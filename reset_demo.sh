#!/bin/bash
set -euo pipefail
git fetch origin demo/ci-correction-base demo/ci-correction
git checkout --no-track -f -B demo/ci-correction origin/demo/ci-correction-base
git reset --hard origin/demo/ci-correction-base
git clean -fdx
git push --force-with-lease -u origin demo/ci-correction:demo/ci-correction
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')"
if [ "$UPSTREAM" != "origin/demo/ci-correction" ]; then echo "wrong upstream: $UPSTREAM"; exit 1; fi
echo "Reset ci-correction to base"
