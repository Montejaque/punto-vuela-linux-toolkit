from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path


APPIMAGE_MAGIC = b"\x7fELF"
USER_AGENT = "PuntoVuelaLinuxToolkit/0.1"


def appimage_directory() -> Path:
    """Return the per-user AppImage storage directory (no root required)."""
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    return data_home / "punto-vuela-linux-toolkit" / "AppImages"


@dataclass(frozen=True)
class AppImageRecord:
    path: Path
    size: int
    executable: bool


class AppImageManager:
    """Safe, user-local AppImage download and update helper.

    Update checks and updates are delegated to AppImageUpdate-compatible
    tooling. An AppImage can only be updated this way when its publisher
    embedded supported update information in the file.
    """

    def __init__(self, directory: Path | None = None) -> None:
        self.directory = (directory or appimage_directory()).expanduser()
        self.directory.mkdir(parents=True, exist_ok=True)

    def list_appimages(self) -> list[AppImageRecord]:
        records: list[AppImageRecord] = []
        for path in sorted(self.directory.glob("*.AppImage"), key=lambda p: p.name.casefold()):
            if not path.is_file():
                continue
            try:
                stat = path.stat()
                records.append(AppImageRecord(path, stat.st_size, os.access(path, os.X_OK)))
            except OSError:
                continue
        return records

    @staticmethod
    def _safe_filename(url: str, filename: str | None = None) -> str:
        candidate = filename or Path(urllib.parse.urlparse(url).path).name
        candidate = Path(candidate).name
        candidate = re.sub(r"[^A-Za-z0-9._+-]", "-", candidate).strip(".-")
        if not candidate:
            raise ValueError("No se pudo determinar un nombre de archivo seguro.")
        if candidate.lower().endswith(".appimage"):
            candidate = candidate[:-len(".appimage")] + ".AppImage"
        else:
            candidate += ".AppImage"
        return candidate

    def download(self, url: str, filename: str | None = None) -> Path:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "https" or not parsed.netloc:
            raise ValueError("Solo se permiten descargas desde direcciones HTTPS.")
        name = self._safe_filename(url, filename)
        destination = self.directory / name
        if destination.exists():
            raise FileExistsError(f"Ya existe una AppImage con ese nombre: {name}. Renómbrala o elimina la anterior antes de descargar otra copia.")
        temporary = destination.with_name(destination.name + ".part")
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                final_url = urllib.parse.urlparse(response.geturl())
                if final_url.scheme != "https":
                    raise ValueError("La descarga ha sido redirigida a una dirección no segura.")
                with temporary.open("wb") as output:
                    first = response.read(4)
                    if first != APPIMAGE_MAGIC:
                        raise ValueError("El archivo descargado no parece ser una AppImage ELF válida.")
                    output.write(first)
                    shutil.copyfileobj(response, output, length=1024 * 1024)
            if temporary.stat().st_size < 1024 * 1024:
                raise ValueError("El archivo descargado es demasiado pequeño para ser una AppImage válida.")
            temporary.chmod(0o755)
            os.replace(temporary, destination)
            destination.chmod(0o755)
            return destination
        except Exception:
            temporary.unlink(missing_ok=True)
            raise


    def ensure_executable(self, path: str | Path) -> Path:
        appimage = Path(path).expanduser().resolve()
        if appimage.parent != self.directory.resolve() or appimage.suffix.lower() != ".appimage":
            raise ValueError("Solo se pueden modificar AppImages de la carpeta administrada.")
        if not appimage.is_file():
            raise FileNotFoundError("No se encuentra la AppImage.")
        appimage.chmod(appimage.stat().st_mode | 0o100)
        return appimage

    def launch(self, path: str | Path) -> None:
        appimage = self.ensure_executable(path)
        subprocess.Popen([str(appimage)], cwd=str(self.directory), start_new_session=True)

    def remove(self, path: str | Path) -> None:
        appimage = Path(path).expanduser().resolve()
        if appimage.parent != self.directory.resolve() or appimage.suffix.lower() != ".appimage":
            raise ValueError("Solo se pueden eliminar AppImages de la carpeta administrada.")
        if not appimage.is_file():
            raise FileNotFoundError("No se encuentra la AppImage.")
        appimage.unlink()

    def _updater_command(self) -> list[str]:
        """Find or securely provision the official x86_64 AppImageUpdate CLI."""
        for command in ("appimageupdatetool", "appimageupdate"):
            found = shutil.which(command)
            if found:
                return [found]

        tools_dir = self.directory.parent / "tools"
        tools_dir.mkdir(parents=True, exist_ok=True)
        updater_path = tools_dir / "appimageupdatetool-x86_64.AppImage"
        if not updater_path.exists():
            api_url = "https://api.github.com/repos/AppImageCommunity/AppImageUpdate/releases/tags/continuous"
            request = urllib.request.Request(api_url, headers={
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": USER_AGENT,
            })
            with urllib.request.urlopen(request, timeout=30) as response:
                release = json.load(response)
            asset = next((item for item in release.get("assets", [])
                          if item.get("name") == "appimageupdatetool-x86_64.AppImage"), None)
            if not asset or not str(asset.get("digest", "")).startswith("sha256:"):
                raise RuntimeError("GitHub no ha proporcionado un SHA-256 verificable para AppImageUpdate.")
            download_request = urllib.request.Request(
                asset["browser_download_url"], headers={"User-Agent": USER_AGENT}
            )
            temporary = updater_path.with_suffix(".AppImage.part")
            digest = hashlib.sha256()
            try:
                with urllib.request.urlopen(download_request, timeout=60) as response, temporary.open("wb") as output:
                    if urllib.parse.urlparse(response.geturl()).scheme != "https":
                        raise RuntimeError("La descarga de AppImageUpdate no usa HTTPS.")
                    while True:
                        chunk = response.read(1024 * 1024)
                        if not chunk:
                            break
                        digest.update(chunk)
                        output.write(chunk)
                expected = asset["digest"].split(":", 1)[1].lower()
                if digest.hexdigest().lower() != expected:
                    raise RuntimeError("El SHA-256 de AppImageUpdate no coincide con el publicado por GitHub.")
                with temporary.open("rb") as updater_file:
                    if updater_file.read(4) != APPIMAGE_MAGIC:
                        raise RuntimeError("El actualizador descargado no es un AppImage ELF válido.")
                temporary.chmod(0o755)
                os.replace(temporary, updater_path)
                updater_path.chmod(0o755)
            except Exception:
                temporary.unlink(missing_ok=True)
                raise
        return [str(updater_path), "--appimage-extract-and-run"]

    def check_update(self, path: str | Path) -> dict[str, str | bool]:
        appimage = Path(path).expanduser().resolve()
        if not appimage.is_file() or appimage.suffix.lower() != ".appimage":
            raise ValueError("La ruta indicada no es una AppImage existente.")
        updater = self._updater_command()
        if not updater:
            return {
                "available": False,
                "supported": False,
                "message": "No está instalado AppImageUpdate. No se puede comprobar la actualización.",
            }
        result = subprocess.run(
            [*updater, "-j", str(appimage)],
            capture_output=True, text=True, timeout=300, check=False,
        )
        output = (result.stdout + "\n" + result.stderr).strip()
        if result.returncode == 0:
            return {
                "available": False,
                "supported": True,
                "message": output or "No se ha detectado ninguna actualización disponible.",
            }
        if result.returncode == 1:
            return {
                "available": True,
                "supported": True,
                "message": output or "Hay una actualización disponible.",
            }
        return {
            "available": False,
            "supported": False,
            "message": output or f"AppImageUpdate terminó con el código {result.returncode}.",
        }

    def update(self, path: str | Path) -> dict[str, str | bool]:
        appimage = Path(path).expanduser().resolve()
        check = self.check_update(appimage)
        if not check["supported"]:
            raise RuntimeError(str(check["message"]))
        if not check["available"]:
            return {"updated": False, "message": str(check["message"])}
        updater = self._updater_command()
        if not updater:
            raise RuntimeError("No se encuentra AppImageUpdate.")
        # Keep the updater's backup so the user can roll back if needed.
        result = subprocess.run(
            [*updater, "--overwrite", str(appimage)],
            capture_output=True, text=True, timeout=1800, check=False,
        )
        output = (result.stdout + "\n" + result.stderr).strip()
        if result.returncode != 0:
            raise RuntimeError(output or f"Falló la actualización (código {result.returncode}).")
        if not appimage.exists() or not os.access(appimage, os.X_OK):
            raise RuntimeError("La actualización terminó, pero no se pudo verificar el archivo ejecutable resultante.")
        return {"updated": True, "message": output or "AppImage actualizada correctamente."}
