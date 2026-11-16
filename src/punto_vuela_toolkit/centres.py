from __future__ import annotations

import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request, urlopen

BASE_URL = "https://puntosvuela.es/centros"
PROVINCES = {
    "almería", "cádiz", "córdoba", "granada",
    "huelva", "jaén", "málaga", "sevilla",
}
CACHE_FILE = Path.home() / ".cache" / "punto-vuela-toolkit" / "centros.json"
POSTAL_RE = re.compile(r"^(.+?)\s*\((\d{5})\)\s*$")


class _DirectoryParser(HTMLParser):
    """Extract official centre names, locations and their detail-page slugs."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.heading: list[str] | None = None
        self.heading_href = ""
        self.paragraph: list[str] | None = None
        self.records: list[dict[str, str]] = []
        self.current_name = ""
        self.current_href = ""
        self.current_paragraphs: list[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:
        attributes = dict(attrs)
        if tag in {"h2", "h3", "h4", "h5", "h6"}:
            self._finish_paragraph()
            self._finish_record()
            self.heading = []
            self.heading_href = ""
        elif tag == "a" and self.heading is not None:
            self.heading_href = attributes.get("href", self.heading_href)
        elif tag == "p":
            self._finish_paragraph()
            self.paragraph = []

    def handle_endtag(self, tag: str) -> None:
        if tag in {"h2", "h3", "h4", "h5", "h6"} and self.heading is not None:
            self.current_name = self._clean("".join(self.heading))
            self.current_href = self.heading_href
            self.heading = None
        elif tag == "p":
            self._finish_paragraph()

    def handle_data(self, data: str) -> None:
        if self.heading is not None:
            self.heading.append(data)
        if self.paragraph is not None:
            self.paragraph.append(data)

    @staticmethod
    def _clean(value: str) -> str:
        return re.sub(r"\s+", " ", value).strip()

    def _finish_paragraph(self) -> None:
        if self.paragraph is not None:
            value = self._clean("".join(self.paragraph))
            if value:
                self.current_paragraphs.append(value)
            self.paragraph = None

    def _finish_record(self) -> None:
        self._finish_paragraph()
        if not self.current_name:
            self.current_paragraphs = []
            self.current_href = ""
            return
        name = self.current_name
        for province in PROVINCES:
            name = re.sub(r",\s*" + re.escape(province) + r"$", "", name, flags=re.I)
        municipality = ""
        province_value = ""
        province_index = -1
        for index, item in enumerate(self.current_paragraphs):
            match = POSTAL_RE.match(item)
            if match and not municipality:
                municipality = match.group(1).strip()
            if item.casefold() in PROVINCES:
                province_value = item
                province_index = index
        if not municipality and province_index > 0:
            municipality = self.current_paragraphs[province_index - 1].strip()
        if name and municipality and province_value:
            slug_match = re.search(r"/centros/([^/?#]+)", self.current_href)
            self.records.append({
                "name": name,
                "municipality": municipality,
                "province": province_value.title(),
                "slug": slug_match.group(1) if slug_match else "",
            })
        self.current_name = ""
        self.current_href = ""
        self.current_paragraphs = []

    def finish(self) -> list[dict[str, str]]:
        self._finish_record()
        return self.records


class _PlainTextParser(HTMLParser):
    """Collect readable page text while ignoring scripts and styles."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.ignored = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in {"script", "style", "noscript"}:
            self.ignored += 1

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "noscript"} and self.ignored:
            self.ignored -= 1

    def handle_data(self, data: str) -> None:
        if not self.ignored:
            value = re.sub(r"\s+", " ", data).strip()
            if value:
                self.parts.append(value)


def _download_page(page: int) -> tuple[int, str]:
    url = BASE_URL if page == 1 else f"{BASE_URL}?page={page}"
    request = Request(url, headers={"User-Agent": "PuntoVuelaToolkit/1.1 (official-centre-directory)"})
    with urlopen(request, timeout=20) as response:
        return page, response.read().decode("utf-8", errors="replace")


def _parse_page(html: str) -> tuple[list[dict[str, str]], int]:
    parser = _DirectoryParser()
    parser.feed(html)
    records = parser.finish()
    page_numbers = [int(n) for n in re.findall(r"[?&]page=(\d+)", html)]
    return records, max(page_numbers, default=1)


def _read_cache() -> list[dict[str, str]]:
    try:
        data = json.loads(CACHE_FILE.read_text(encoding="utf-8"))
        if isinstance(data, list) and len(data) >= 100:
            return data
    except (OSError, ValueError):
        pass
    return []


def load_centres(force: bool = False) -> list[dict[str, str]]:
    """Load all official centres, refreshing a local cache when possible."""
    cached = _read_cache()
    cache_has_profile_links = bool(cached) and all(isinstance(item, dict) and "slug" in item for item in cached)
    if cached and cache_has_profile_links and not force:
        try:
            if time.time() - CACHE_FILE.stat().st_mtime < 7 * 24 * 60 * 60:
                return cached
        except OSError:
            pass

    try:
        _, first_html = _download_page(1)
        first_records, last_page = _parse_page(first_html)
        all_records = list(first_records)
        if last_page > 1:
            with ThreadPoolExecutor(max_workers=8) as pool:
                futures = [pool.submit(_download_page, page) for page in range(2, last_page + 1)]
                for future in as_completed(futures):
                    _, html = future.result()
                    records, _ = _parse_page(html)
                    all_records.extend(records)
    except Exception:
        if cached:
            return cached
        raise

    unique: dict[tuple[str, str], dict[str, str]] = {}
    for item in all_records:
        key = (item["name"].casefold(), item["province"].casefold())
        unique[key] = item
    result = sorted(unique.values(), key=lambda item: item["name"].casefold())
    if len(result) < 100:
        if cached:
            return cached
        raise RuntimeError("El directorio oficial no ha devuelto suficientes centros. Inténtalo más tarde.")

    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    CACHE_FILE.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    return result


def _parse_centre_details(html: str, slug: str) -> dict[str, str]:
    parser = _PlainTextParser()
    parser.feed(html)
    text = " ".join(parser.parts)
    contact_match = re.search(r"Información de contacto\s+(.*?)\s+Agentes de innovación local", text, flags=re.I)
    ail_match = re.search(r"Agentes de innovación local\s+(.+?)(?:\s+Horario de apertura|\s+Verificar disponibilidad|\s+Te estamos esperando)", text, flags=re.I)
    if not contact_match or not ail_match:
        raise RuntimeError("La ficha oficial no contiene los datos de contacto y del AIL en un formato reconocible.")
    contact_section = contact_match.group(1)
    ail_name = re.sub(r"\s+", " ", ail_match.group(1)).strip()
    ail_name = re.split(r"\s+(?:Guadalinfo|Punto Vuela)\b", ail_name, maxsplit=1, flags=re.I)[0].strip()
    emails = re.findall(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", contact_section, flags=re.I)
    phones = re.findall(r"(?<!\d)(?:\+34[\s.-]?)?[6789](?:[\s()./-]*\d){8}(?!\d)", contact_section)
    phone = " / ".join(dict.fromkeys(re.sub(r"\s+", " ", value).strip() for value in phones))
    return {"slug": slug, "ail": ail_name, "phone": phone, "email": emails[0] if emails else "", "source_url": f"{BASE_URL}/{quote(slug)}"}


def load_centre_details(slug: str) -> dict[str, str]:
    """Fetch public AIL/contact details from the selected official centre page."""
    clean_slug = re.sub(r"[^a-zA-Z0-9-]", "", slug or "")
    if not clean_slug:
        raise ValueError("Este centro no tiene una ficha pública identificable en el directorio oficial.")
    url = f"{BASE_URL}/{quote(clean_slug)}"
    request = Request(url, headers={"User-Agent": "PuntoVuelaToolkit/1.1 (official-centre-contact-prefill)"})
    with urlopen(request, timeout=20) as response:
        html = response.read().decode("utf-8", errors="replace")
    return _parse_centre_details(html, clean_slug)
