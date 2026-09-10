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
git fetch origin demo/ci-correction-base demo/ci-correction

git checkout --no-track -f -B demo/ci-correction origin/demo/ci-correction-base

git reset --hard origin/demo/ci-correction-base

git clean -fdx

BASE_SHA="$(git rev-parse origin/demo/ci-correction-base)"

HEAD_SHA="$(git rev-parse HEAD)"

if [ "$HEAD_SHA" != "$BASE_SHA" ]; then
  echo "CI_CORRECTION_FAIL: HEAD does not match base"
  exit 1
fi

if ! git diff --quiet; then
  echo "CI_CORRECTION_FAIL: working tree differs from base"
  git status --short
  git diff
  exit 1
fi

grep -q "raise NotImplementedError" src/config.py || {
  echo "CI_CORRECTION_FAIL: base is not pristine"
  echo "=== remote base src/config.py ==="
  git show origin/demo/ci-correction-base:src/config.py
  echo "=== working src/config.py ==="
  cat src/config.py
  exit 1
}

if grep -R "PORT_COMPATIBILITY_LEVEL" src tests TASK.md README.md .github 2>/dev/null | grep -q .; then echo "CI_CORRECTION_FAIL: hidden contract leaked into repo"; exit 1; fi

git push --force-with-lease -u origin demo/ci-correction:demo/ci-correction

UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')"
if [ "$UPSTREAM" != "origin/demo/ci-correction" ]; then echo "CI_CORRECTION_FAIL: wrong upstream: $UPSTREAM"; exit 1; fi

LOG="${TMPDIR:-/tmp}/workflow-ci-correction.log"
rm -f "$LOG"
rm -rf .agent
workflow init
workflow remote gh
WORKFLOW_DEBUG_AGENT_TURNS=1 workflow run 2>&1 | tee "$LOG"

python3 <<'PY'
import json, sys
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
th = s.get("task_history", []) or []
# Find the last CHANGED task (holds the real CI) if final delivery is SATISFIED/SKIPPED
effective = d
if d.get("task_outcome") in ("SATISFIED", "SKIPPED", None) and d.get("ci_status") == "SKIPPED":
    for t in reversed(th):
        if t.get("outcome") == "CHANGED" and t.get("ci_status") in ("CI_PASSED", "CI_NOT_DETECTED"):
            effective = t
            break
print({"status": s.get("status"), "phase": d.get("phase"), "outcome": d.get("task_outcome"), "commit_sha": d.get("commit_sha"), "push_status": d.get("push_status"), "ci_status": d.get("ci_status"), "effective_commit": effective.get("commit_sha"), "effective_ci": effective.get("ci_status"), "history": [(t.get("task_id"), t.get("outcome"), t.get("ci_status")) for t in th]})
assert s.get("status") == "COMPLETED", f"status={s.get('status')}"
assert d.get("phase") == "TASK_COMPLETED", f"phase={d.get('phase')}"
# Final task may be SATISFIED/SKIPPED (e.g. task002 testing only); CI lives on last CHANGED
# Smart check: at least one history entry is CI_PASSED, and effective CI is PASSED/SKIPPED-with-history
ci_ok = effective.get("ci_status") == "CI_PASSED" or any(t.get("ci_status") == "CI_PASSED" for t in th)
if not ci_ok:
    print(f"CI_CORRECTION_FAIL: no CI_PASSED in history; effective ci_status={effective.get('ci_status')} delivery={d.get('ci_status')}")
    sys.exit(1)
# ci_runs may live on effective or current delivery
ci_runs = effective.get("ci_runs") or d.get("ci_runs") or []
commit_sha = effective.get("commit_sha") or d.get("commit_sha")
if ci_ok and not ci_runs:
    # Allow task_history SATISFIED case to pass with effective CI_PASSED even if runs not persisted in delivery
    print(f"CI runs not in effective but history has CI_PASSED — allowing (commit {commit_sha})")
else:
    if not any(r.get("status") == "completed" and r.get("conclusion") == "success" and r.get("headSha") == commit_sha for r in ci_runs):
        print(f"CI_CORRECTION_FAIL: final persisted CI snapshot does not match effective commit: {ci_runs} commit={commit_sha}")
        sys.exit(1)
PY

# Delivery SHAs
mapfile -t DELIVERY_SHAS < <(git rev-list --reverse "${BASE_SHA}..HEAD")
if [ "${#DELIVERY_SHAS[@]}" -lt 2 ]; then echo "CI_CORRECTION_FAIL: expected >=2 commits after base, got ${#DELIVERY_SHAS[@]}"; exit 1; fi
INITIAL_SHA="${DELIVERY_SHAS[0]}"
FINAL_SHA="$(git rev-parse HEAD)"

command -v gh >/dev/null 2>&1 || { echo "CI_CORRECTION_FAIL: gh CLI required"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "CI_CORRECTION_FAIL: gh not authenticated"; exit 1; }

RUNS_JSON="$(gh run list --branch demo/ci-correction --workflow CI --limit 10 --json databaseId,headSha,status,conclusion 2>&1)"
RUNS_JSON="$RUNS_JSON" FINAL_SHA="$FINAL_SHA" INITIAL_SHA="$INITIAL_SHA" python3 <<'PY'
import json, os, sys
runs = json.loads(os.environ["RUNS_JSON"])
final_sha = os.environ["FINAL_SHA"]
initial_sha = os.environ["INITIAL_SHA"]
initial_failure = any(r.get("headSha") == initial_sha and r.get("status") == "completed" and r.get("conclusion") == "failure" for r in runs)
final_success = any(r.get("headSha") == final_sha and r.get("status") == "completed" and r.get("conclusion") == "success" for r in runs)
if not initial_failure:
    print(f"CI_CORRECTION_FAIL: no failure for initial SHA {initial_sha}: {runs}")
    sys.exit(1)
if not final_success:
    print(f"CI_CORRECTION_FAIL: no success for final SHA {final_sha}: {runs}")
    sys.exit(1)
print("Remote CI: initial failure + final success verified")
PY

echo "=== Demo Result ==="
python3 <<'PY'
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print(f"name: ci-correction\nresult: PASS\nstatus: {s.get('status')}\nphase: {d.get('phase')}\noutcome: {d.get('task_outcome')}\ncommit_sha: {d.get('commit_sha')}\npush_status: {d.get('push_status')}\nci_status: {d.get('ci_status')}")
PY
echo "CI_CORRECTION_PASS"
