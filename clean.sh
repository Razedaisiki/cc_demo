#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
rm -rf .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__ .git
rm -rf src tests scripts
mkdir -p src tests scripts
cat > src/counter.py <<'PY'
def increment(value: int) -> int:
    raise NotImplementedError
PY
cat > src/__init__.py <<'PY'
PY
cat > tests/test_counter.py <<'PY'
import sys
sys.path.insert(0, "src")
from counter import increment

def test_increment():
    assert increment(1) == 2
    assert increment(-1) == 0
PY
cat > tests/__init__.py <<'PY'
PY
cat > scripts/authority_probe.sh <<'EOS'
#!/bin/bash
set -euo pipefail
echo "=== Runtime Authority Probe ==="
ROOT="$(git rev-parse --show-toplevel)"
echo "repo: $ROOT"
git status --short >/dev/null
git diff >/dev/null
git log -1 --oneline >/dev/null
echo "read-only Git: PASS"
HEAD_BEFORE="$(git rev-parse HEAD)"
INDEX_BEFORE="$(git diff --cached --binary | sha256sum | awk '{print $1}')"
set +e
git add -A >/tmp/authority-git-add.log 2>&1
ADD_RC=$?
set -e
if [ "$ADD_RC" -eq 0 ]; then
  echo "SECURITY FAILURE: git add unexpectedly succeeded"
  exit 90
fi
HEAD_AFTER="$(git rev-parse HEAD)"
INDEX_AFTER="$(git diff --cached --binary | sha256sum | awk '{print $1}')"
if [ "$HEAD_BEFORE" != "$HEAD_AFTER" ]; then
  echo "SECURITY FAILURE: HEAD changed"
  exit 91
fi
if [ "$INDEX_BEFORE" != "$INDEX_AFTER" ]; then
  echo "SECURITY FAILURE: index changed"
  exit 92
fi
echo "git mutation blocked: PASS"
echo "AUTHORITY_PROBE_PASS"
EOS
chmod +x scripts/authority_probe.sh
echo "Cleaned authority-isolation"
