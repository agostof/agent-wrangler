#!/usr/bin/env bash
set -euo pipefail

CONFIGURE=false INSTALL_PATH=/usr/local/bin curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | sudo -E bash
