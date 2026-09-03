#!/bin/bash
set -euo pipefail
while true; do
  if [ -f .agent/state.json ]; then
    out="$(python3 <<'PY'
import json
s = json.load(open(".agent/state.json"))
d = s.get("delivery", {})
phase = d.get("phase")
sha = d.get("commit_sha")
sid = s.get("session_id")
if phase == "WAITING_CI":
    print(f"================================\nREADY_TO_KILL\nphase={phase}\ncommit_sha={sha}\nsession_id={sid}\n================================")
else:
    print(f"phase={phase} sha={sha}")
PY
)"
    echo "$out"
  fi
  sleep 1
done
