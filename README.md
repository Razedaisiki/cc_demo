# execution-evidence — local

## What this demo proves
Claude Code tool_use → tool_result pairing is correct and real validation evidence reaches Reviewer.

## How to run
```bash
bash run_demo.sh
```

## Expected final state
- status=COMPLETED, phase=TASK_COMPLETED, outcome=CHANGED, push_status=SKIPPED
- Log contains [CodeAgent tool] + pytest passed

## Reset strategy
Fresh local git repo each run (rm -rf .git .agent).

## Result
- PASS → EXECUTION_EVIDENCE_PASS
- FAIL → EXECUTION_EVIDENCE_FAIL
