#!/bin/bash
set -euo pipefail
git fetch origin demo/ci-resume-base demo/ci-resume
git checkout --no-track -f -B demo/ci-resume origin/demo/ci-resume-base
git reset --hard origin/demo/ci-resume-base
git clean -fdx
git push --force-with-lease -u origin demo/ci-resume:demo/ci-resume
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>&1)"
if [ "$UPSTREAM" != "origin/demo/ci-resume" ]; then echo "wrong upstream: $UPSTREAM"; exit 1; fi
echo "Reset ci-resume to base"
