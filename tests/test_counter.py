import sys
sys.path.insert(0, "src")
from counter import increment

def test_increment():
    assert increment(1) == 2
    assert increment(-1) == 0
