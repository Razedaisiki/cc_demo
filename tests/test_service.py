import sys
sys.path.insert(0, "src")
from service import ServiceClient
from service_config import ServiceConfig


def test_client():
    c = ServiceClient(base_url="https://example.com")
    assert c.base_url == "https://example.com"
    assert c.timeout_ms == 5000


def test_client_custom_timeout():
    c = ServiceClient(base_url="https://example.com", timeout_ms=2500)
    assert c.timeout_ms == 2500


def test_client_from_config_consumes_timeout():
    config = ServiceConfig(base_url="https://example.com", timeout_ms=4321)
    c = ServiceClient.from_config(config)
    assert c.base_url == "https://example.com"
    assert c.timeout_ms == 4321
