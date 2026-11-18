#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${1:-agentsandbox}"
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  FALLBACK="$(docker ps --format '{{.Names}}' | grep -E '^agentsandbox' | head -n1 || true)"
  if [ -n "$FALLBACK" ]; then
    CONTAINER="$FALLBACK"
  fi
fi

exec docker exec -it --user agent "$CONTAINER" bash
