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
git fetch origin demo/ci-resume-base demo/ci-resume
git checkout --no-track -f -B demo/ci-resume origin/demo/ci-resume-base
git reset --hard origin/demo/ci-resume-base
git clean -fdx
BASE_SHA="$(git rev-parse origin/demo/ci-resume-base)"
HEAD_SHA="$(git rev-parse HEAD)"
if [ "$HEAD_SHA" != "$BASE_SHA" ]; then echo "ci-resume reset failed: HEAD != base"; exit 1; fi
if ! git diff --quiet; then echo "ci-resume reset failed: working tree differs"; git status --short; exit 1; fi
grep -q "raise NotImplementedError" src/user_id.py || { echo "CI_RESUME_FAIL: base branch is not pristine"; exit 1; }

git push --force-with-lease -u origin demo/ci-resume:demo/ci-resume
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>&1)"
if [ "$UPSTREAM" != "origin/demo/ci-resume" ]; then echo "CI_RESUME_FAIL: wrong upstream: $UPSTREAM"; exit 1; fi

rm -rf .agent
xxx init
xxx remote gh

LOG="${TMPDIR:-/tmp}/xxx-ci-resume.log"
rm -f "$LOG"
XXX_DEBUG_AGENT_TURNS=1 xxx run 2>&1 | tee "$LOG"
# Note: this demo is designed for manual interrupt; if run uninterrupted it will complete normally
python3 <<'PY'
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
print({"status": s.get("status"), "phase": d.get("phase"), "sha": d.get("commit_sha"), "ci_status": d.get("ci_status")})
PY
