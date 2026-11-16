import json
import unittest
from io import BytesIO
from urllib.error import HTTPError, URLError
from unittest.mock import patch

from punto_vuela_toolkit import email_sender


class EmailSenderTests(unittest.TestCase):
    def valid_payload(self):
        return {
            "center": "Montejaque",
            "municipality": "Montejaque",
            "province": "Málaga",
            "contact": "Agente de Innovación Local",
            "phone": "600000000",
            "reply_email": "ail@example.org",
            "application": "Editor de texto",
            "purpose": "Necesidad de edición de documentos",
            "data_protection_read": True,
            "privacy_policy_read": True,
            "terms_accepted": True,
        }

    def test_successful_send_returns_worker_confirmation(self):
        response = BytesIO(b'{"ok":true,"message":"Solicitud enviada."}')
        response.status = 200
        with patch.object(email_sender, "urlopen", return_value=response):
            self.assertEqual(email_sender.send_application_request(self.valid_payload()), "Solicitud enviada.")

    def test_http_error_keeps_actionable_worker_message_and_status(self):
        error = HTTPError(
            email_sender.WORKER_URL, 503, "Service unavailable", {},
            BytesIO(b'{"ok":false,"message":"Falta configurar el servicio."}')
        )
        with patch.object(email_sender, "urlopen", side_effect=error):
            with self.assertRaisesRegex(RuntimeError, r"Falta configurar el servicio.*HTTP 503"):
                email_sender.send_application_request(self.valid_payload())

    def test_network_error_explains_connection_failure(self):
        with patch.object(email_sender, "urlopen", side_effect=URLError("DNS failure")):
            with self.assertRaisesRegex(RuntimeError, "DNS failure"):
                email_sender.send_application_request(self.valid_payload())

    def test_missing_required_field_is_rejected_before_network(self):
        payload = self.valid_payload()
        payload["purpose"] = ""
        with patch.object(email_sender, "urlopen") as request:
            with self.assertRaisesRegex(ValueError, "Faltan datos obligatorios"):
                email_sender.send_application_request(payload)
            request.assert_not_called()

    def test_missing_legal_consent_is_rejected_before_network(self):
        payload = self.valid_payload()
        payload["terms_accepted"] = False
        with patch.object(email_sender, "urlopen") as request:
            with self.assertRaisesRegex(ValueError, "información legal"):
                email_sender.send_application_request(payload)
            request.assert_not_called()


    def test_health_check_returns_worker_configuration(self):
        response = BytesIO(b'{"ok":true,"configured":true,"checks":{"rateLimitKv":true}}')
        response.status = 200
        with patch.object(email_sender, "urlopen", return_value=response):
            result = email_sender.check_mail_service()
        self.assertTrue(result["ok"])
        self.assertTrue(result["checks"]["rateLimitKv"])
        self.assertEqual(result["http_status"], 200)

    def test_health_check_preserves_missing_configuration_diagnostics(self):
        error = HTTPError(
            email_sender.WORKER_URL + "/health", 503, "Service unavailable", {},
            BytesIO(b'{"ok":false,"checks":{"googleRefreshToken":false},"message":"Falta un secreto."}')
        )
        with patch.object(email_sender, "urlopen", side_effect=error):
            result = email_sender.check_mail_service()
        self.assertFalse(result["ok"])
        self.assertFalse(result["checks"]["googleRefreshToken"])
        self.assertEqual(result["http_status"], 503)


if __name__ == "__main__":
    unittest.main()
