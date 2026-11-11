from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

from .appimages import AppImageManager

FEED_URL = "https://appimage.github.io/feed.json"
USER_AGENT = "PuntoVuelaLinuxToolkit/0.2"
MAX_GLIBC_UBUNTU_20 = (2, 31, 0)


def _version_tuple(value: str | None) -> tuple[int, ...] | None:
    if not value:
        return None
    match = re.search(r"(\d+(?:\.\d+)*)", str(value))
    if not match:
        return None
    parts = [int(part) for part in match.group(1).split(".")]
    return tuple(parts + [0] * max(0, 3 - len(parts)))


def _github_repo(entry: dict[str, Any]) -> str | None:
    for link in entry.get("links") or []:
        if str(link.get("type", "")).lower() == "github":
            value = str(link.get("url", "")).strip().rstrip("/")
            if value.startswith("https://github.com/"):
                value = value.split("https://github.com/", 1)[1]
            if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", value):
                return value
    return None


class AppImageCatalog:
    """Reader for the community AppImage JSON feed and GitHub release assets."""

    def __init__(self, manager: AppImageManager | None = None) -> None:
        self.manager = manager or AppImageManager()
        self.cache_file = self.manager.directory.parent / "catalog-feed.json"

    @staticmethod
    def _request(url: str, timeout: int = 30) -> bytes:
        request = urllib.request.Request(url, headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json, application/octet-stream",
        })
        with urllib.request.urlopen(request, timeout=timeout) as response:
            if urllib.parse.urlparse(response.geturl()).scheme != "https":
                raise RuntimeError("El catálogo ha redirigido a una conexión no segura.")
            return response.read()

    def _feed(self, force: bool = False) -> dict[str, Any]:
        if not force and self.cache_file.exists() and time.time() - self.cache_file.stat().st_mtime < 12 * 3600:
            try:
                return json.loads(self.cache_file.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                pass
        raw = self._request(FEED_URL, timeout=60)
        feed = json.loads(raw.decode("utf-8"))
        if not isinstance(feed.get("items"), list):
            raise RuntimeError("El feed comunitario no tiene el formato esperado.")
        self.cache_file.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.cache_file.with_suffix(".part")
        temporary.write_text(json.dumps(feed, ensure_ascii=False), encoding="utf-8")
        temporary.replace(self.cache_file)
        return feed

    def search(self, query: str = "", force: bool = False, limit: int = 500) -> list[dict[str, Any]]:
        feed = self._feed(force=force)
        needle = query.strip().casefold()
        results: list[dict[str, Any]] = []
        for entry in feed["items"]:
            name = str(entry.get("name") or "").strip()
            if not name:
                continue
            description = re.sub(r"<[^>]+>", " ", str(entry.get("description") or ""))
            categories = [str(item) for item in (entry.get("categories") or []) if item]
            author = (entry.get("authors") or [{}])[0] if entry.get("authors") else {}
            author_name = str(author.get("name") or "")
            haystack = " ".join((name, description, " ".join(categories), author_name)).casefold()
            if needle and needle not in haystack:
                continue
            glibc = str(entry.get("glibc_required") or "")
            required = _version_tuple(glibc)
            compatible = required is None or required <= MAX_GLIBC_UBUNTU_20
            download_url = next((str(link.get("url")) for link in (entry.get("links") or [])
                                 if str(link.get("type", "")).lower() == "download" and link.get("url")), "")
            results.append({
                "name": name,
                "description": description.strip()[:500],
                "category": categories[0] if categories else "Sin categoría",
                "author": author_name,
                "license": str(entry.get("license") or "No indicada"),
                "glibc": glibc or "No declarada",
                "compatibleUbuntu20": compatible,
                "compatibility": ("Compatible por requisito glibc declarado" if required and compatible
                                  else "Puede ser compatible; versión de glibc no declarada" if required is None
                                  else "No compatible con Ubuntu 20.04 (glibc requerida superior a 2.31)"),
                "downloadUrl": download_url,
                "repository": _github_repo(entry) or "",
                "catalogUrl": "https://appimage.github.io/" + urllib.parse.quote(name) + "/",
                "iconUrl": ("https://appimage.github.io/" + str((entry.get("icons") or [""])[0]).lstrip("/")) if (entry.get("icons") or []) else "",
                "screenshotUrl": (str((entry.get("screenshots") or [""])[0]) if str((entry.get("screenshots") or [""])[0]).startswith("https://") else "https://appimage.github.io/" + str((entry.get("screenshots") or [""])[0]).lstrip("/")) if (entry.get("screenshots") or []) else "",
            })
            if len(results) >= limit:
                break
        return results

    def _download_result(self, name: str, url: str, filename: str | None = None) -> dict[str, Any]:
        path = self.manager.download(url, filename)
        try:
            update = self.manager.check_update(path)
        except Exception as exc:
            update = {"supported": False, "available": False, "message": str(exc)}
        if update.get("supported") and update.get("available"):
            message = f"{name} se ha descargado. El comprobador detecta una versión posterior; puedes instalarla desde Mis aplicaciones."
        elif update.get("supported"):
            message = f"{name} se ha descargado y no se detectan actualizaciones."
        else:
            message = f"{name} se ha descargado. No se ha podido comprobar la versión: {update.get('message', 'sin metadatos compatibles')}."
        return {"ok": True, "path": str(path), "updateAvailable": bool(update.get("available")), "message": message}

    def install(self, app_name: str) -> dict[str, Any]:
        entry = next((item for item in self.search(app_name, limit=5000)
                      if item["name"].casefold() == app_name.casefold()), None)
        if not entry:
            raise RuntimeError("No se ha encontrado la aplicación en el catálogo.")
        if not entry["compatibleUbuntu20"]:
            raise RuntimeError("Esta aplicación declara una glibc superior a la de Ubuntu 20.04. Se bloquea la instalación para evitar una aplicación que no arranque.")
        repository = entry.get("repository")
        if not repository:
            direct_url = entry.get("downloadUrl", "")
            if urllib.parse.urlparse(direct_url).path.lower().endswith(".appimage"):
                result = self._download_result(entry["name"], direct_url)
                desktop = self.manager.integrate(result["path"], entry["name"])
                result["desktopEntry"] = str(desktop)
                result["message"] = entry["name"] + " descargada e integrada en el menú de aplicaciones."
                return result
            raise RuntimeError("El catálogo no facilita un enlace directo ni un repositorio GitHub con una versión descargable. Abre la ficha de descarga del autor.")
        api_url = "https://api.github.com/repos/" + repository + "/releases/latest"
        release = json.loads(self._request(api_url, timeout=30).decode("utf-8"))
        assets = release.get("assets") or []
        appimage_assets = [asset for asset in assets if str(asset.get("name", "")).lower().endswith(".appimage")]
        x86_assets = [asset for asset in appimage_assets if re.search(r"(x86_64|amd64|x64)", asset["name"], re.I)]
        generic_assets = [asset for asset in appimage_assets if not re.search(r"(aarch64|arm64|armv7|armhf|i386|i686|x86_64|amd64|x64)", asset["name"], re.I)]
        selected = x86_assets or generic_assets
        if not selected:
            raise RuntimeError("No se ha encontrado un archivo AppImage en la última versión de GitHub. Consulta la página de descargas del desarrollador.")
        asset = selected[0]
        result = self._download_result(entry["name"], asset["browser_download_url"], asset["name"])
        desktop = self.manager.integrate(result["path"], entry["name"])
        result["desktopEntry"] = str(desktop)
        result["message"] = entry["name"] + " descargada e integrada en el menú de aplicaciones."
        return result
