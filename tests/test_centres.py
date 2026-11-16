import unittest

from punto_vuela_toolkit.centres import _parse_centre_details, _parse_page


class CentreDirectoryParserTests(unittest.TestCase):
    def test_extracts_name_municipality_province_and_profile_slug(self):
        html = """
        <html><body>
          <h2>Elige desde donde te acompañamos</h2>
          <h4><a href="/centros/montejaque">MONTEJAQUE</a></h4>
          <p>Andalucia 48</p>
          <p>Montejaque (29360)</p>
          <p>Málaga</p>
          <p>633402959</p>
          <h4><a href="/centros/alameda">ALAMEDA</a></h4>
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
                {"name": "MONTEJAQUE", "municipality": "Montejaque", "province": "Málaga", "slug": "montejaque"},
                {"name": "ALAMEDA", "municipality": "Alameda", "province": "Málaga", "slug": "alameda"},
            ],
        )

    def test_extracts_public_ail_contact_details(self):
        html = """
        <html><body>
          <h3>Información de contacto</h3>
          <p>Avenida Andalucía 48 CP 29360 - Montejaque - Málaga</p>
          <p>633402959</p>
          <p>montejaque@puntosvuela.es</p>
          <p>Centro Certificador FNMT: SI</p>
          <h3>Agentes de innovación local</h3>
          <p>Nombre Apellidos del AIL</p>
          <h3>Horario de apertura</h3>
        </body></html>
        """
        result = _parse_centre_details(html, "montejaque")
        self.assertEqual(result["ail"], "Nombre Apellidos del AIL")
        self.assertEqual(result["phone"], "633402959")
        self.assertEqual(result["email"], "montejaque@puntosvuela.es")
        self.assertEqual(result["source_url"], "https://puntosvuela.es/centros/montejaque")


if __name__ == "__main__":
    unittest.main()
