#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d .git ]; then
  git init -q
  git config user.email "demo@test.com"
  git config user.name "demo"
  git remote add origin git@github.com:Razedaisiki/cc_demo.git 2>/dev/null || true
fi
git fetch origin demo/multifile-service-base demo/multifile-service
git checkout --no-track -f -B demo/multifile-service origin/demo/multifile-service-base
git reset --hard origin/demo/multifile-service-base
git clean -fdx
BASE_SHA="$(git rev-parse origin/demo/multifile-service-base)"
HEAD_SHA="$(git rev-parse HEAD)"
if [ "$HEAD_SHA" != "$BASE_SHA" ]; then echo "MULTIFILE_FAIL: HEAD != base"; exit 1; fi
if ! git diff --quiet; then echo "MULTIFILE_FAIL: working tree differs from base"; git status --short; exit 1; fi
grep -q "from dataclasses import dataclass" src/service_config.py || { echo "MULTIFILE_FAIL: base not pristine"; exit 1; }

git push --force-with-lease -u origin demo/multifile-service:demo/multifile-service
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>&1)"
if [ "$UPSTREAM" != "origin/demo/multifile-service" ]; then echo "MULTIFILE_FAIL: wrong upstream: $UPSTREAM"; exit 1; fi

rm -rf .agent
workflow init
workflow remote gh

LOG="${TMPDIR:-/tmp}/workflow-multifile.log"
rm -f "$LOG"
WORKFLOW_DEBUG_AGENT_TURNS=1 workflow run 2>&1 | tee "$LOG"

grep -q "parsed 1 tasks from plan" "$LOG" || { echo "MULTIFILE_SERVICE_FAIL: expected 1 task"; exit 1; }

python3 <<'PY'
import json, sys
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print({"status": s.get("status"), "phase": d.get("phase"), "outcome": d.get("task_outcome"), "push_status": d.get("push_status"), "ci_status": d.get("ci_status"), "commit_sha": d.get("commit_sha")})
assert s.get("status") == "COMPLETED", f"status={s.get('status')}"
assert d.get("phase") == "TASK_COMPLETED", f"phase={d.get('phase')}"
assert d.get("task_outcome") == "CHANGED", f"outcome={d.get('task_outcome')}"
assert d.get("push_status") == "SUCCESS", f"push_status={d.get('push_status')}"
assert d.get("ci_status") == "CI_PASSED", f"ci_status={d.get('ci_status')}"
PY

COUNT="$(git rev-list --count "${BASE_SHA}..HEAD")"
if [ "$COUNT" != "1" ]; then echo "MULTIFILE_SERVICE_FAIL: expected 1 commit after base, got $COUNT"; exit 1; fi

CHANGED="$(git diff --name-only "${BASE_SHA}..HEAD")"
echo "Changed files: $CHANGED"
echo "$CHANGED" | grep -q "src/" || { echo "MULTIFILE_SERVICE_FAIL: no src/ changes"; exit 1; }
echo "$CHANGED" | grep -q "tests/" || { echo "MULTIFILE_SERVICE_FAIL: no tests/ changes"; exit 1; }
NUM="$(echo "$CHANGED" | wc -l | tr -d ' ')"
if [ "$NUM" -lt 3 ]; then echo "MULTIFILE_SERVICE_FAIL: expected >=3 files, got $NUM"; exit 1; fi

COMMIT_SHA="$(git rev-parse HEAD)"
DELIVERY_SHA="$(python3 -c "import json; print(json.load(open('.agent/state.json')).get('delivery',{}).get('commit_sha',''))")"
if [ "$COMMIT_SHA" != "$DELIVERY_SHA" ]; then echo "MULTIFILE_SERVICE_FAIL: commit_sha mismatch $COMMIT_SHA != $DELIVERY_SHA"; exit 1; fi

python3 <<PY2
import json, sys
s = json.load(open(".agent/state.json"))
runs = s.get("delivery", {}).get("ci_runs") or []
sha = s.get("delivery", {}).get("commit_sha")
if not runs:
    print("MULTIFILE_SERVICE_FAIL: ci_runs missing")
    sys.exit(1)
ok = any(r.get("status") == "completed" and r.get("conclusion") == "success" and r.get("headSha") == sha for r in runs)
if not ok:
    print(f"MULTIFILE_SERVICE_FAIL: no successful CI run for {sha}: {runs}")
    sys.exit(1)
print("ci_runs: PASS")
PY2

echo "=== Demo Result ==="
python3 <<'PY'
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print(f"name: multifile-service\nresult: PASS\nstatus: {s.get('status')}\nphase: {d.get('phase')}\noutcome: {d.get('task_outcome')}\ncommit_sha: {d.get('commit_sha')}\npush_status: {d.get('push_status')}\nci_status: {d.get('ci_status')}")
PY
echo "MULTIFILE_SERVICE_PASS"
