#!/usr/bin/env bash
set -euo pipefail

UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/usr/local/share/uv/tools sudo -E uv tool install hermes-agent
# Alternative official installer:
# curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
echo "Configure Hermes with: hermes setup --portal (or hermes model)"
