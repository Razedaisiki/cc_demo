#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
rm -rf .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__ .git
rm -rf src tests
mkdir -p src tests
cat > src/greeting.py <<'PY'
def greet(name: str) -> str:
    cleaned = name.strip()
    if not cleaned:
        raise ValueError("name cannot be empty")
    return f"Hello, {cleaned}!"
PY
cat > src/__init__.py <<'PY'
PY
cat > tests/test_greeting.py <<'PY'
import sys
sys.path.insert(0, "src")
from greeting import greet
def test_greet():
    assert greet("Alice") == "Hello, Alice!"
    assert greet("  Bob  ") == "Hello, Bob!"
def test_empty():
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
PY
cat > tests/__init__.py <<'PY'
PY
echo "Cleaned already-satisfied"
