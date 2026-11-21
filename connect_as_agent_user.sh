#!/usr/bin/env bash
# Open a shell (default) or a tmux session as `agent` inside the running
# agentsandbox container.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: connect_as_agent_user.sh [options] [container]

Without options, opens a bash shell as `agent` (same as before).

Options:
  --tmux            Attach to the tmux session in the container, creating it if needed
  --cc              Same as --tmux, using iTerm2's tmux integration (tmux -CC):
                    tmux windows open as native iTerm2 tabs
  --session NAME    tmux session name (default: $AW_SESSION or "agents")
  --prefix KEY      tmux prefix key for this session, e.g. C-a. Without it, the
                    session uses TMUX_PREFIX from .env (default C-b). When --tmux
                    is run from inside a host tmux, C-a is used automatically so
                    the two prefixes don't clash; pass --prefix C-b to keep C-b.
  -h, --help        Show this help

Container defaults to "agentsandbox", falling back to the first running
container whose name starts with "agentsandbox" (e.g. from `docker compose run`).

Remote example (iTerm2 -> ssh -> container tmux):
  ssh -t linuxhost '~/agent-wrangler/connect_as_agent_user.sh --cc'
EOF
}

MODE=shell
SESSION="${AW_SESSION:-agents}"
PREFIX=""
CONTAINER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --tmux) MODE=tmux ;;
    --cc) MODE=cc ;;
    --session)
      [ $# -ge 2 ] || { echo "error: --session needs a value" >&2; exit 2; }
      SESSION="$2"; shift ;;
    --prefix)
      [ $# -ge 2 ] || { echo "error: --prefix needs a value" >&2; exit 2; }
      PREFIX="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) CONTAINER="$1" ;;
  esac
  shift
done

CONTAINER="${CONTAINER:-agentsandbox}"
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  FALLBACK="$(docker ps --format '{{.Names}}' | grep -E '^agentsandbox' | head -n1 || true)"
  if [ -n "$FALLBACK" ]; then
    CONTAINER="$FALLBACK"
  fi
fi

if [ "$MODE" = shell ]; then
  exec docker exec -it --user agent "$CONTAINER" bash
fi

if ! docker exec --user agent "$CONTAINER" sh -c 'command -v tmux' >/dev/null 2>&1; then
  echo "error: tmux is not installed in container '$CONTAINER'." >&2
  echo "Enable it with: ln -s available/install_tmux.sh scripts/install_tmux.sh && docker compose build" >&2
  exit 1
fi

# Nested in a host tmux (not -CC): use C-a inside unless a prefix was chosen,
# either with --prefix or with TMUX_PREFIX in .env.
if [ "$MODE" = tmux ] && [ -z "$PREFIX" ] && [ -n "${TMUX:-}" ]; then
  CONTAINER_PREFIX="$(docker exec --user agent "$CONTAINER" printenv AW_TMUX_PREFIX 2>/dev/null || true)"
  if [ -z "$CONTAINER_PREFIX" ]; then
    PREFIX="C-a"
    echo "Inside a host tmux: using prefix C-a in the container session (override with --prefix)." >&2
  fi
fi

CMD=(tmux)
[ "$MODE" = cc ] && CMD+=(-CC)
CMD+=(new-session -A -s "$SESSION")
if [ -n "$PREFIX" ]; then
  # Session-level option: other sessions keep their own prefix.
  CMD+=(";" set-option prefix "$PREFIX" ";" bind-key "$PREFIX" send-prefix)
fi

exec docker exec -it --user agent "$CONTAINER" "${CMD[@]}"
