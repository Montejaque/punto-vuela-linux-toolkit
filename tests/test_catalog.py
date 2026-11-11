import tempfile
import unittest
from pathlib import Path

from punto_vuela_toolkit.catalog import AppImageCatalog, _github_repo, _version_tuple
from punto_vuela_toolkit.appimages import AppImageManager


class CatalogCompatibilityTests(unittest.TestCase):
    def test_glibc_versions_are_parsed(self):
        self.assertEqual(_version_tuple("2.31"), (2, 31))
        self.assertEqual(_version_tuple("glibc 2.34"), (2, 34))
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


if __name__ == "__main__":
    unittest.main()
