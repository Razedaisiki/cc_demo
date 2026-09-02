# authority-isolation — local

## What this demo proves
- Direct git mutation blocked via hook, read-only git allowed
- Wrapper script internal git add blocked via sandbox
- Runtime still commits normally

## How to run
```bash
bash run_demo.sh
```

## Expected final state
- status=COMPLETED, phase=TASK_COMPLETED, outcome=CHANGED
- Log contains authority_probe.sh + AUTHORITY_PROBE_PASS
- Working tree clean

## Reset strategy
Fresh local git repo each run.
