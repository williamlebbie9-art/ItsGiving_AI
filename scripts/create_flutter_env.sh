#!/usr/bin/env bash
set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

cat > .env <<EOF
AI_PROVIDER=${AI_PROVIDER:-firebase}
FIREBASE_FUNCTIONS_URL=${FIREBASE_FUNCTIONS_URL:-}
FIREBASE_IMAGE_FUNCTIONS_URL=${FIREBASE_IMAGE_FUNCTIONS_URL:-}
EOF

chmod 600 .env
