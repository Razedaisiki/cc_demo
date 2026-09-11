# cc_demo

Demo repository for **agent-system** integration and behavior testing.

Each demo lives on its own `demo/<name>` branch and is designed to exercise a specific agent workflow, recovery path, or safety guarantee.

Some GitHub-based demos use a pair of branches:

* `demo/<name>-base` — immutable reset/baseline branch
* `demo/<name>` — working branch used to run the demo

Local demos create a fresh local Git repository on each run and therefore do not need a separate base branch.

## Demo branches

| Branch                        | Type   | Description                                                                                                                                                                                                                                    |
| ----------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `demo/ci-correction`          | GitHub | **CI failure → correction → successful delivery.** The agent implements `parse_port`, pushes the change, observes CI feedback, and completes the correction/delivery workflow.                                                                 |
| `demo/ci-correction-base`     | Base   | Immutable baseline for `demo/ci-correction`. Used to reset the working branch before rerunning the demo.                                                                                                                                       |
| `demo/multifile-service`      | GitHub | **Multi-file implementation and delivery.** Adds `timeout_ms` configuration across config parsing, environment overrides, `ServiceClient`, and tests, then pushes the completed change and verifies CI.                                        |
| `demo/multifile-service-base` | Base   | Immutable baseline for `demo/multifile-service`. Used to restore the demo to its initial state.                                                                                                                                                |
| `demo/ci-resume`              | GitHub | **Resume from a real CI checkpoint.** Demonstrates that `WAITING_CI` is recoverable state: execution can be interrupted while CI is pending and later resumed without rerunning the CodeAgent or creating a new commit.                        |
| `demo/ci-resume-base`         | Base   | Immutable baseline for `demo/ci-resume`. Used to reset the working branch before a new run.                                                                                                                                                    |
| `demo/already-satisfied`      | Local  | **No-op / already-satisfied task.** Demonstrates that a clean repository which already satisfies the requested task can legitimately finish with `SATISFIED`, without creating a commit or modifying the working tree.                         |
| `demo/authority-isolation`    | Local  | **Git authority isolation.** Demonstrates that the coding agent cannot directly mutate Git state—even indirectly through wrapper scripts—while read-only Git access remains available and the runtime can still perform the authorized commit. |
| `demo/execution-evidence`     | Local  | **Execution evidence propagation.** Demonstrates correct Claude Code `tool_use → tool_result` pairing and verifies that real execution/test evidence reaches the Reviewer before the task is accepted.                                         |

## Demo details

### `demo/ci-correction`

GitHub delivery / CI correction demo.

The task is to implement:

```python
parse_port(value: str) -> int
```

with whitespace handling, decimal parsing, port-range validation (`1..65535`), and `ValueError` for invalid input.

This demo exercises the end-to-end GitHub delivery path, including implementation, tests, commit/push, CI observation, and correction when CI feedback requires another change.

Reset source:

```text
demo/ci-correction-base
    ↓
demo/ci-correction
```

---

### `demo/multifile-service`

Multi-file service configuration demo.

The task adds timeout support across the existing service configuration system:

* `ServiceConfig.timeout_ms`
* default timeout of `5000`
* valid range `1..60000`
* JSON `timeout_ms` support
* `SERVICE_TIMEOUT_MS` environment override
* validation with `ValueError`
* propagation into `ServiceClient`
* corresponding test updates

This demo is intended to exercise a change that spans multiple files and responsibilities rather than a single isolated function.

Expected delivery result includes a changed task, successful push, and passing CI for the final commit.

Reset source:

```text
demo/multifile-service-base
    ↓
demo/multifile-service
```

---

### `demo/ci-resume`

CI checkpoint / recovery demo.

This demo proves that `WAITING_CI` is actual recoverable workflow state rather than merely a log event.

The run can be interrupted after the task has been implemented and pushed but while CI is still pending. A subsequent resume continues from that checkpoint.

Important property:

```text
HEAD / commit_sha remain unchanged after resume
CodeAgent is not rerun
CI monitoring continues
→ TASK_COMPLETED / CI_PASSED
```

Reset source:

```text
demo/ci-resume-base
    ↓
demo/ci-resume
```

---

### `demo/already-satisfied`

Local no-op demo.

This demonstrates the valid case where the repository is already in the requested final state before the agent performs any modification.

Expected result:

```text
task_outcome = SATISFIED
commit_sha   = None
HEAD         = unchanged
working tree = clean
```

The important distinction is that **clean + already correct** may legitimately produce `SATISFIED`; the agent does not need to manufacture a change or empty commit.

A fresh local Git repository is created for each run.

---

### `demo/authority-isolation`

Local authority-boundary demo.

This demo verifies that repository mutation authority belongs to the runtime rather than the coding agent.

It checks that:

* direct Git mutation from the agent is blocked
* read-only Git operations remain available
* hiding Git mutation inside a wrapper script is also blocked by the sandbox
* the runtime can still perform the authorized commit normally

Expected result is a completed changed task with a clean working tree and successful authority probe.

A fresh local Git repository is created for each run.

---

### `demo/execution-evidence`

Local execution-evidence demo.

This demo verifies that actual tool execution results are preserved and propagated through the agent workflow.

In particular, it checks:

```text
Claude Code tool_use
        ↓
matching tool_result
        ↓
real command / pytest evidence
        ↓
Reviewer
```

The Reviewer therefore evaluates real validation evidence rather than an unsupported claim that tests were run successfully.

Successful runs emit:

```text
EXECUTION_EVIDENCE_PASS
```

A fresh local Git repository is created for each run.

## Running a demo

Switch to the desired branch and follow that branch's `README.md` / `TASK.md`.

Most demos provide a convenience script:

```bash
bash run_demo.sh
```

Some demos, such as `ci-resume`, require additional scripts because interruption and recovery are part of the scenario.

## Repository conventions

* `TASK.md` defines the coding task used by the demo.
* `README.md` documents the scenario, expected result, and reset strategy.
* `run_demo.sh` runs the scenario.
* `clean.sh` removes generated demo state where applicable.
* `reset_demo.sh` restores GitHub-backed working branches from their immutable `-base` branch where applicable.
* `.github/workflows/` contains CI used by GitHub delivery demos.
* `src/` and `tests/` contain the small fixture project used by the scenario.

The branches are intentionally independent demo fixtures rather than stages of one application.
