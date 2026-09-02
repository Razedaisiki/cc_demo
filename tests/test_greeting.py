import sys
sys.path.insert(0, "src")
from greeting import greet
def test_greet():
    assert greet("Alice") == "Hello, Alice!"
    assert greet("  Bob  ") == "Hello, Bob!"
def test_empty():
    import pytest
    try:
        greet("")
        assert False
    except ValueError:
        pass
    try:
        greet("   ")
        assert False
    except ValueError:
        pass
