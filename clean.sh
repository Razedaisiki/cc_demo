#!/bin/bash
set -euo pipefail
# GH demo: reset via reset_demo.sh for full history purge; this is local cache clean
rm -rf .agent .pytest_cache __pycache__ src/__pycache__ tests/__pycache__
echo "Cleaned multifile-service (local cache); for full reset use reset_demo.sh"
