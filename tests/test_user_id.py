import sys
sys.path.insert(0, "src")
from user_id import format_user_id
def test_format():
    assert format_user_id("Hello World") == "hello-world"
    assert format_user_id("  Foo  ") == "foo"
