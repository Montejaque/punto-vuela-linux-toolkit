import unittest

from punto_vuela_toolkit.centres import _parse_page


class CentreDirectoryParserTests(unittest.TestCase):
    def test_extracts_name_municipality_and_province(self):
        html = """
        <html><body>
          <h2>Elige desde donde te acompañamos</h2>
          <h4>MONTEJAQUE</h4>
          <p>Andalucia 48</p>
          <p>Montejaque (29360)</p>
          <p>Málaga</p>
          <p>633402959</p>
          <h4>ALAMEDA</h4>
          <p>de la Constitución, 23</p>
          <p>Alameda (29530)</p>
          <p>Málaga</p>
          <p>952711292</p>
          <a href="/centros?page=76">76</a>
        </body></html>
        """
        records, last_page = _parse_page(html)
        self.assertEqual(last_page, 76)
        self.assertEqual(
            records,
            [
                {"name": "MONTEJAQUE", "municipality": "Montejaque", "province": "Málaga"},
                {"name": "ALAMEDA", "municipality": "Alameda", "province": "Málaga"},
            ],
        )


if __name__ == "__main__":
    unittest.main()
