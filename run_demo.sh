#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Deterministic baseline: full canonical src/tests
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
rm -rf .git .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__
git init -q
git config user.email "demo@test.com"
git config user.name "demo"
git add .
git commit -qm "baseline: already-satisfied"

HEAD_BEFORE="$(git rev-parse HEAD)"

rm -rf .agent
xxx init
xxx remote local

LOG="${TMPDIR:-/tmp}/xxx-already-satisfied.log"
rm -f "$LOG"
XXX_DEBUG_AGENT_TURNS=1 xxx run 2>&1 | tee "$LOG"

python3 <<'PY'
import json, subprocess, sys
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print({"status": s.get("status"), "phase": d.get("phase"), "outcome": d.get("task_outcome"), "commit_sha": d.get("commit_sha"), "push_status": d.get("push_status"), "ci_status": d.get("ci_status")})
assert s.get("status") == "COMPLETED", f"status={s.get('status')}"
assert d.get("phase") == "TASK_COMPLETED", f"phase={d.get('phase')}"
assert d.get("task_outcome") == "SATISFIED", f"outcome={d.get('task_outcome')}"
assert not d.get("commit_sha"), f"commit_sha should be None for SATISFIED, got {d.get('commit_sha')}"
assert d.get("push_status") == "SKIPPED", f"push_status={d.get('push_status')}"
assert d.get("ci_status") == "SKIPPED", f"ci_status={d.get('ci_status')}"
out = subprocess.check_output(["git", "status", "--porcelain"], text=True)
assert out.strip() == "", f"working tree not clean: {out!r}"
PY

HEAD_AFTER="$(git rev-parse HEAD)"
if [ "$HEAD_BEFORE" != "$HEAD_AFTER" ]; then echo "ALREADY_SATISFIED_FAIL: HEAD changed"; exit 1; fi
COUNT="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
if [ "$COUNT" != "1" ]; then echo "ALREADY_SATISFIED_FAIL: expected 1 commit, got $COUNT"; exit 1; fi

echo "=== Demo Result ==="
python3 <<'PY'
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print(f"name: already-satisfied\nresult: PASS\nstatus: {s.get('status')}\nphase: {d.get('phase')}\noutcome: {d.get('task_outcome')}\ncommit_sha: {d.get('commit_sha')}\npush_status: {d.get('push_status')}\nci_status: {d.get('ci_status')}")
PY
echo "ALREADY_SATISFIED_PASS"
