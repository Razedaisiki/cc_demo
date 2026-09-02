#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
rm -rf .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__ .git
rm -rf src tests
mkdir -p src tests
cat > src/slug.py <<'PY'
def normalize_slug(value: str) -> str:
    raise NotImplementedError("normalize_slug not implemented")
PY
cat > src/__init__.py <<'PY'
PY
cat > tests/test_slug.py <<'PY'
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
PY
cat > tests/__init__.py <<'PY'
PY
echo "Cleaned execution-evidence"
