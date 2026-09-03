import sys
sys.path.insert(0, "src")
from config import parse_port
def test_valid():
    assert parse_port("8080") == 8080
    assert parse_port(" 443 ") == 443
def test_invalid():
    import pytest
    for v in ("", "abc", "0", "65536"):
        try:
            parse_port(v)
            assert False, f"{v!r} should raise"
        except ValueError:
            pass
