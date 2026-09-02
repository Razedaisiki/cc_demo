# already-satisfied — local

## What this demo proves
Clean already-correct repo can legitimately SATISFIED with no new commit (vs dirty+SATISFIED forbidden).

## How to run
```bash
bash run_demo.sh
```

## Expected final state
- task_outcome=SATISFIED, commit_sha=None, HEAD unchanged, working tree clean

## Reset strategy
Fresh local git repo each run.
