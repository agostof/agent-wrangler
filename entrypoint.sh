#!/usr/bin/env bash

if ! id -u agentuser >/dev/null 2>&1; then
  useradd -u "$UID" -o -m agentuser 2>/dev/null || true
fi

exec "$@"
