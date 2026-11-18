#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://antigravity.google/cli/install.sh | bash
if [ -f "$HOME/.local/bin/agy" ]; then
  sudo install -m 0755 "$HOME/.local/bin/agy" /usr/local/bin/agy
fi
echo "Launch Antigravity with: agy"
