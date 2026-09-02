import pytest
import sys
sys.path.insert(0, "src")
from slug import normalize_slug

def test_normalize_slug():
    assert normalize_slug("Hello World") == "hello-world"
    assert normalize_slug("  Foo Bar  ") == "foo-bar"
    assert normalize_slug("already-clean") == "already-clean"

def test_empty_slug():
    with pytest.raises(ValueError):
        normalize_slug("")
    with pytest.raises(ValueError):
        normalize_slug("   ")
