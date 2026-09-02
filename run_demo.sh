#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Deterministic baseline: full src/tests reconstruction
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
rm -rf .git .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__
git init -q
git config user.email "demo@test.com"
git config user.name "demo"
git add .
git commit -qm "baseline: execution-evidence"

xxx init
xxx remote local

LOG="${TMPDIR:-/tmp}/xxx-execution-evidence.log"
rm -f "$LOG"

XXX_DEBUG_AGENT_TURNS=1 xxx run 2>&1 | tee "$LOG"

python3 <<'PY'
import json, sys
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print({"status": s.get("status"), "phase": d.get("phase"), "outcome": d.get("task_outcome"), "commit_sha": d.get("commit_sha"), "push_status": d.get("push_status"), "ci_status": d.get("ci_status")})
assert s.get("status") == "COMPLETED", f"status={s.get('status')}"
assert d.get("phase") == "TASK_COMPLETED", f"phase={d.get('phase')}"
assert d.get("task_outcome") == "CHANGED", f"outcome={d.get('task_outcome')}"
assert d.get("commit_sha"), "missing commit_sha"
assert d.get("push_status") == "SKIPPED", f"push_status={d.get('push_status')}"
assert d.get("ci_status") == "SKIPPED", f"ci_status={d.get('ci_status')}"
PY

# Real Bash pytest tool evidence (not just README mention)
python3 <<PY2
import sys
log = open("$LOG", encoding="utf-8").read().splitlines()
pytest_tools = [l for l in log if "[CodeAgent tool] Bash:" in l and "pytest" in l]
if not pytest_tools:
    print("EXECUTION_EVIDENCE_FAIL: CodeAgent did not execute pytest")
    sys.exit(1)
print("pytest tool evidence: PASS")
PY2

# Harness itself verifies final repo tests pass
python3 -m pytest -q || { echo "EXECUTION_EVIDENCE_FAIL: harness pytest failed"; exit 1; }

echo "=== Demo Result ==="
python3 <<'PY'
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print(f"name: execution-evidence\nresult: PASS\nstatus: {s.get('status')}\nphase: {d.get('phase')}\noutcome: {d.get('task_outcome')}\ncommit_sha: {d.get('commit_sha')}\npush_status: {d.get('push_status')}\nci_status: {d.get('ci_status')}")
PY
echo "EXECUTION_EVIDENCE_PASS"
