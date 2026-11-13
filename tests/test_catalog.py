import tempfile
import unittest
from pathlib import Path

from punto_vuela_toolkit.catalog import AppImageCatalog, _github_repo, _version_tuple
from punto_vuela_toolkit.appimages import AppImageManager


class CatalogCompatibilityTests(unittest.TestCase):
    def test_glibc_versions_are_parsed(self):
        self.assertEqual(_version_tuple("2.31"), (2, 31, 0))
        self.assertEqual(_version_tuple("glibc 2.34"), (2, 34, 0))
        self.assertEqual(_version_tuple("2.31.1"), (2, 31, 1))
        self.assertIsNone(_version_tuple("unknown"))

    def test_github_repository_is_extracted(self):
        entry = {"links": [{"type": "GitHub", "url": "https://github.com/owner/project"}]}
        self.assertEqual(_github_repo(entry), "owner/project")

    def test_search_marks_ubuntu_20_compatibility(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = AppImageManager(Path(tmp) / "AppImages")
            catalog = AppImageCatalog(manager)
            catalog._feed = lambda force=False: {"items": [
                {"name": "GoodApp", "description": "Works", "categories": ["Utility"],
                 "authors": [{"name": "Author"}], "license": "MIT",
                 "links": [{"type": "GitHub", "url": "owner/good"}],
                 "glibc_required": "2.28"},
                {"name": "NewApp", "description": "Needs new glibc", "categories": ["Utility"],
                 "authors": [{"name": "Author"}], "links": [],
                 "glibc_required": "2.34"},
                {"name": "UnknownApp", "description": "No glibc data", "categories": [],
                 "authors": [], "links": []}
            ]}
            results = catalog.search("")
            by_name = {item["name"]: item for item in results}
            self.assertTrue(by_name["GoodApp"]["compatibleUbuntu20"])
            self.assertFalse(by_name["NewApp"]["compatibleUbuntu20"])
            self.assertIn("no declarada", by_name["UnknownApp"]["compatibility"])

    def test_search_matches_author_and_category(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = AppImageManager(Path(tmp) / "AppImages")
            catalog = AppImageCatalog(manager)
            catalog._feed = lambda force=False: {"items": [
                {"name": "Editor", "description": "Text editor", "categories": ["Office"],
                 "authors": [{"name": "Example Author"}], "links": []}
            ]}
            self.assertEqual(catalog.search("example")[0]["name"], "Editor")
            self.assertEqual(catalog.search("office")[0]["name"], "Editor")


    def test_public_github_discovery_excludes_private_and_requires_appimage_release(self):
        import json
        with tempfile.TemporaryDirectory() as tmp:
            manager = AppImageManager(Path(tmp) / "AppImages")
            catalog = AppImageCatalog(manager)
            responses = {
                "https://api.github.com/users/Montejaque/repos?type=public&sort=updated&per_page=100": [
                    {"name":"public-tool", "full_name":"Montejaque/public-tool", "private":False, "archived":False, "disabled":False, "html_url":"https://github.com/Montejaque/public-tool", "description":"Public tool", "owner":{"avatar_url":"https://avatars.githubusercontent.com/u/1"}},
                    {"name":"private-tool", "full_name":"Montejaque/private-tool", "private":True, "archived":False, "disabled":False},
                    {"name":"archived-tool", "full_name":"Montejaque/archived-tool", "private":False, "archived":True, "disabled":False}
                ],
                "https://api.github.com/repos/Montejaque/public-tool/releases/latest": {
                    "tag_name":"v1.2.0", "html_url":"https://github.com/Montejaque/public-tool/releases/tag/v1.2.0",
                    "assets":[{"name":"public-tool-x86_64.AppImage", "browser_download_url":"https://example.com/public-tool.AppImage"}]
                }
            }
            catalog._request = lambda url, timeout=30: json.dumps(responses[url]).encode("utf-8")
            items = catalog.discover_public_github_tools(force=True)
            self.assertEqual(len(items), 1)
            self.assertEqual(items[0]["repository"], "Montejaque/public-tool")
            self.assertEqual(items[0]["version"], "v1.2.0")
            self.assertEqual(items[0]["downloadUrl"], "https://example.com/public-tool.AppImage")
if __name__ == "__main__":
    unittest.main()
