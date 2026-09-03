import json
import os
import sys
sys.path.insert(0, "src")
from service_config import ServiceConfig


def test_base_url():
    c = ServiceConfig(base_url="https://example.com")
    assert c.base_url == "https://example.com"


def test_default_timeout():
    c = ServiceConfig(base_url="https://example.com")
    assert c.timeout_ms == 5000


def test_explicit_timeout():
    c = ServiceConfig(base_url="https://example.com", timeout_ms=1500)
    assert c.timeout_ms == 1500


def test_invalid_timeout_low():
    try:
        ServiceConfig(base_url="https://example.com", timeout_ms=0)
    except ValueError:
        return
    raise AssertionError("expected ValueError")


def test_invalid_timeout_high():
    try:
        ServiceConfig(base_url="https://example.com", timeout_ms=60001)
    except ValueError:
        return
    raise AssertionError("expected ValueError")


def test_invalid_timeout_type():
    try:
        ServiceConfig(base_url="https://example.com", timeout_ms="abc")
    except ValueError:
        return
    raise AssertionError("expected ValueError")


def test_from_json_provides_timeout():
    payload = json.dumps({"base_url": "https://example.com", "timeout_ms": 2500})
    c = ServiceConfig.from_json(payload)
    assert c.base_url == "https://example.com"
    assert c.timeout_ms == 2500


def test_from_json_uses_default_timeout():
    payload = json.dumps({"base_url": "https://example.com"})
    c = ServiceConfig.from_json(payload)
    assert c.timeout_ms == 5000


def test_env_overrides_json_timeout(tmp_path):
    cfg_path = tmp_path / "service.json"
    cfg_path.write_text(json.dumps({"base_url": "https://example.com", "timeout_ms": 1000}))
    c = ServiceConfig.load(str(cfg_path), env={"SERVICE_TIMEOUT_MS": "3000"})
    assert c.timeout_ms == 3000


def test_env_absent_keeps_json_timeout(tmp_path):
    cfg_path = tmp_path / "service.json"
    cfg_path.write_text(json.dumps({"base_url": "https://example.com", "timeout_ms": 1500}))
    c = ServiceConfig.load(str(cfg_path), env={})
    assert c.timeout_ms == 1500


def test_env_invalid_timeout_raises(tmp_path):
    cfg_path = tmp_path / "service.json"
    cfg_path.write_text(json.dumps({"base_url": "https://example.com", "timeout_ms": 1500}))
    try:
        ServiceConfig.load(str(cfg_path), env={"SERVICE_TIMEOUT_MS": "99999"})
    except ValueError:
        return
    raise AssertionError("expected ValueError")
