#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
# Local clean only; GH reset via reset_demo.sh
rm -rf .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__
cat > src/user_id.py <<'PY'
def format_user_id(value: str) -> str:
    raise NotImplementedError
PY
echo "Cleaned ci-resume (local)"
