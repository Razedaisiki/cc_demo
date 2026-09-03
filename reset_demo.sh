#!/bin/bash
set -euo pipefail
git fetch origin demo/multifile-service-base demo/multifile-service
git checkout --no-track -f -B demo/multifile-service origin/demo/multifile-service-base
git reset --hard origin/demo/multifile-service-base
git clean -fdx
git push --force-with-lease -u origin demo/multifile-service:demo/multifile-service
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>&1)"
if [ "$UPSTREAM" != "origin/demo/multifile-service" ]; then echo "wrong upstream: $UPSTREAM"; exit 1; fi
echo "Reset multifile-service to base"
