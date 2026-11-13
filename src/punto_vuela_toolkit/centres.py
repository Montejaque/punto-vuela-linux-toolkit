from __future__ import annotations

import json
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import Request, urlopen

BASE_URL = "https://puntosvuela.es/centros"
PROVINCES = {
    "almería", "cádiz", "córdoba", "granada",
    "huelva", "jaén", "málaga", "sevilla",
}
CACHE_FILE = Path.home() / ".cache" / "punto-vuela-toolkit" / "centros.json"
POSTAL_RE = re.compile(r"^(.+?)\s*\((\d{5})\)\s*$")


class _DirectoryParser(HTMLParser):
    """Extract centre headings and paragraph text from the official directory."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.heading: list[str] | None = None
        self.paragraph: list[str] | None = None
        self.records: list[dict[str, str]] = []
        self.current_name = ""
        self.current_paragraphs: list[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in {"h2", "h3", "h4", "h5", "h6"}:
            self._finish_paragraph()
            self._finish_record()
            self.heading = []
        elif tag == "p":
            self._finish_paragraph()
            self.paragraph = []

    def handle_endtag(self, tag: str) -> None:
        if tag in {"h2", "h3", "h4", "h5", "h6"} and self.heading is not None:
            self.current_name = self._clean("".join(self.heading))
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
            return
        name = self.current_name
        for province in PROVINCES:
            name = re.sub(r",\s*" + re.escape(province) + r"$", "", name, flags=re.I)
        municipality = ""
        province_value = ""
        for item in self.current_paragraphs:
            match = POSTAL_RE.match(item)
            if match and not municipality:
                municipality = match.group(1).strip()
            if item.casefold() in PROVINCES:
                province_value = item
        if name and municipality and province_value:
            self.records.append({
                "name": name,
                "municipality": municipality,
                "province": province_value.title(),
            })
        self.current_name = ""
        self.current_paragraphs = []

    def finish(self) -> list[dict[str, str]]:
        self._finish_record()
        return self.records


def _download_page(page: int) -> tuple[int, str]:
    url = BASE_URL if page == 1 else f"{BASE_URL}?page={page}"
    request = Request(url, headers={"User-Agent": "PuntoVuelaToolkit/1.0 (official-centre-directory)"})
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
    if cached and not force:
        return cached

    _, first_html = _download_page(1)
    first_records, last_page = _parse_page(first_html)
    all_records = list(first_records)
    if last_page > 1:
        with ThreadPoolExecutor(max_workers=8) as pool:
            futures = [pool.submit(_download_page, page) for page in range(2, last_page + 1)]
            for future in as_completed(futures):
                page, html = future.result()
                records, _ = _parse_page(html)
                all_records.extend(records)

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
