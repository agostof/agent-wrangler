#!/usr/bin/env bash
# Installs tmux (~1.5 MB with its libraries) plus pinned copies of the
# tmux-resurrect and tmux-continuum plugins (~0.5 MB, plain shell scripts).
#
# The plugins are only loaded when TMUX_RESURRECT=true in .env
# (see config/tmux.conf). To leave tmux out of the image entirely:
#   rm scripts/install_tmux.sh && docker compose build
set -euo pipefail

TMUX_RESURRECT_VERSION="${TMUX_RESURRECT_VERSION:-v4.0.0}"
TMUX_CONTINUUM_VERSION="${TMUX_CONTINUUM_VERSION:-v3.1.0}"
PLUGIN_DIR=/usr/local/share/tmux/plugins

sudo apt-get update
sudo apt-get install -y --no-install-recommends tmux
sudo rm -rf /var/lib/apt/lists/*

sudo mkdir -p "$PLUGIN_DIR"
sudo git clone --quiet --depth 1 --branch "$TMUX_RESURRECT_VERSION" \
  https://github.com/tmux-plugins/tmux-resurrect "$PLUGIN_DIR/tmux-resurrect"
sudo git clone --quiet --depth 1 --branch "$TMUX_CONTINUUM_VERSION" \
  https://github.com/tmux-plugins/tmux-continuum "$PLUGIN_DIR/tmux-continuum"
sudo rm -rf "$PLUGIN_DIR"/*/.git

tmux -V
echo "tmux plugins: resurrect $TMUX_RESURRECT_VERSION, continuum $TMUX_CONTINUUM_VERSION in $PLUGIN_DIR"
