# multifile-service — gh

Multi-file service integration demo.

## How to run
```bash
bash run_demo.sh
```

## Expected final state
- parsed 1 tasks, outcome=CHANGED, push_status=SUCCESS, ci_status=CI_PASSED, ci_runs success for final SHA

## Reset strategy
Immutable base `demo/multifile-service-base` → working `demo/multifile-service`.
