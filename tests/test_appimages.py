from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from punto_vuela_toolkit.appimages import AppImageManager


class FakeResponse:
    def __init__(self, payload: bytes, url: str = "https://downloads.example/app.AppImage") -> None:
        self.payload = payload
        self.position = 0
        self.url = url

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def geturl(self):
        return self.url

    def read(self, size: int = -1) -> bytes:
        if size < 0:
            size = len(self.payload) - self.position
        chunk = self.payload[self.position:self.position + size]
        self.position += len(chunk)
        return chunk


class AppImageManagerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.manager = AppImageManager(Path(self.temp.name) / "AppImages")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_directory_is_created(self):
        self.assertTrue(self.manager.directory.is_dir())

    def test_rejects_non_https_download(self):
        with self.assertRaises(ValueError):
            self.manager.download("http://example.com/app.AppImage")

    def test_download_validates_elf_and_sets_executable(self):
        payload = b"\x7fELF" + b"x" * (1024 * 1024)
        with patch("punto_vuela_toolkit.appimages.urllib.request.urlopen",
                   return_value=FakeResponse(payload)):
            path = self.manager.download("https://downloads.example/app.AppImage")
        self.assertTrue(path.is_file())
        self.assertTrue(os.access(path, os.X_OK))
        self.assertEqual(path.read_bytes()[:4], b"\x7fELF")

    def test_rejects_invalid_payload_and_cleans_partial_file(self):
        with patch("punto_vuela_toolkit.appimages.urllib.request.urlopen",
                   return_value=FakeResponse(b"NOPE" + b"x" * 1024)):
            with self.assertRaises(ValueError):
                self.manager.download("https://downloads.example/bad.AppImage")
        self.assertEqual(list(self.manager.directory.iterdir()), [])

    def test_does_not_overwrite_existing_download(self):
        existing = self.manager.directory / "app.AppImage"
        existing.write_bytes(b"existing")
        with self.assertRaises(FileExistsError):
            self.manager.download("https://downloads.example/app.AppImage")
        self.assertEqual(existing.read_bytes(), b"existing")

    def test_lists_only_appimage_files(self):
        image = self.manager.directory / "one.AppImage"
        image.write_bytes(b"ELF")
        (self.manager.directory / "notes.txt").write_text("not an app")
        records = self.manager.list_appimages()
        self.assertEqual([record.path.name for record in records], ["one.AppImage"])


if __name__ == "__main__":
    unittest.main()
