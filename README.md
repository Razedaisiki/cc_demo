# ci-resume — gh

## What this demo proves
WAITING_CI checkpoint is real recovery, not logging.

## How to run
Terminal A: `bash run_demo.sh`
Terminal B: `bash watch_state.sh` → wait for READY_TO_KILL
Ctrl-C Terminal A, then `bash resume_demo.sh`

## Expected final state
- phase=TASK_COMPLETED, ci_status=CI_PASSED
- HEAD/commit_sha unchanged on resume, no CodeAgent rerun

## Reset strategy
Immutable base `demo/ci-resume-base` → working `demo/ci-resume`.
