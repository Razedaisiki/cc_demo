#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Must have been interrupted during WAITING_CI
python3 <<'PY'
import json, sys
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
if d.get("phase") != "WAITING_CI":
    print(f"ERROR: resume demo was not interrupted during WAITING_CI (phase={d.get('phase')})")
    sys.exit(1)
print(f"Pre-resume: phase=WAITING_CI commit={d.get('commit_sha')} session={s.get('session_id')}")
PY

SESSION_BEFORE="$(python3 -c "import json; print(json.load(open('.agent/state.json')).get('session_id',''))")"
COMMIT_BEFORE="$(python3 -c "import json; print(json.load(open('.agent/state.json')).get('delivery',{}).get('commit_sha',''))")"
HEAD_BEFORE="$(git rev-parse HEAD)"

RESUME_LOG="${TMPDIR:-/tmp}/workflow-ci-resume-resume.log"
rm -f "$RESUME_LOG"
workflow resume 2>&1 | tee "$RESUME_LOG"

python3 <<PY
import json, sys
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
assert s.get("status") == "COMPLETED", f"status={s.get('status')}"
assert d.get("phase") == "TASK_COMPLETED", f"phase={d.get('phase')}"
assert d.get("ci_status") == "CI_PASSED", f"ci_status={d.get('ci_status')}"
assert d.get("commit_sha") == "${COMMIT_BEFORE}", "commit_sha changed on resume"
PY

HEAD_AFTER="$(git rev-parse HEAD)"
if [ "$HEAD_BEFORE" != "$HEAD_AFTER" ]; then echo "FAIL: HEAD changed on resume"; exit 1; fi

SESSION_AFTER="$(python3 -c "import json; print(json.load(open('.agent/state.json')).get('session_id',''))")"
if [ "$SESSION_BEFORE" != "$SESSION_AFTER" ]; then echo "FAIL: session_id changed"; exit 1; fi

if grep -q "\[CodeAgent\] task" "$RESUME_LOG"; then echo "FAIL: CodeAgent reran on resume"; exit 1; fi
if grep -q "\[CodeAgent tool\]" "$RESUME_LOG"; then echo "FAIL: CodeAgent tool reran on resume"; exit 1; fi
grep -q "plan.md reused (resume)" "$RESUME_LOG" || { echo "FAIL: plan reuse not found"; exit 1; }

echo "=== Demo Result ==="
python3 <<PY
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print(f"name: ci-resume\nresult: PASS\nstatus: {s.get('status')}\nphase: {d.get('phase')}\ncommit_sha: {d.get('commit_sha')}\nci_status: {d.get('ci_status')}")
PY
echo "CI_RESUME_PASS"
