# agent-wrangler

A lightweight Docker-based sandbox (`agentsandbox`) for running and managing AI agent tooling (e.g. Antigravity, Claude, Codex, Copilot, OpenCode, Pi) in a controlled, reproducible environment.

## Overview

`agent-wrangler` provides a consistent development/runtime container for trying and using multiple agent CLIs without polluting your host environment. It keeps agent binaries/configuration inside a reproducible Docker setup while still granting the permissions some tools need to function (for example `bubblewrap`-based workflows and elevated container capabilities) and mapping your host user's `UID:GID` into the non-root `agent` user inside the container.

It includes:

* isolated workspace (`/work`) and project (`/projects`) directories
* mounted agent configuration (Antigravity, Claude, Codex, Pi, etc.)
* Node 22 (`nvm`), Python 3, and `uv` (`uv` / `uvx`) preinstalled
* interactive terminal support (tmux-friendly)
* reproducible environment via Docker

## Files

* `Dockerfile` – builds the `agentsandbox` image
* `docker-compose.yml` – defines the `agentsandbox` runtime container
* `docker-entrypoint.sh` – container startup logic (maps `LOCAL_UID` / `LOCAL_GID` to `agent` and drops root privileges via `gosu`)
* `connect_as_agent_user.sh` – helper to open an interactive shell as `agent` inside the running `agentsandbox` container
* `env.example` – environment variable template
* `scripts/` – install scripts for agent tooling
* `tools/` – repository indexing utilities (`/tools/index-repo.sh`)

## Getting Started

### 1. Copy environment file

```bash
cp env.example .env
```

Edit `.env` as needed (set `CALLER_UID` / `CALLER_GID` to match `id -u` / `id -g` on your host).

---

### 2. Enable desired tools

See Script Configuration below.

---

### 3. Build the container

```bash
docker compose build
```

(or `./build.sh`)

---

### 4. Start the sandbox

```bash
docker compose run --rm app
```

or start in the background and attach with the helper script:

```bash
docker compose up -d
./connect_as_agent_user.sh
```

---

## Script Configuration

The `scripts/` directory controls which tools are installed into the container.

### Structure

```text
scripts/
├── available/
│   ├── install_aider.sh
│   ├── install_antigravity.sh
│   ├── install_claude.sh
│   ├── install_codex.sh
│   ├── install_copilot.sh
│   ├── install_gemini.sh
│   ├── install_goose.sh
│   ├── install_hermes.sh
│   ├── install_ohmypi.sh
│   ├── install_openclaw.sh
│   ├── install_opencode.sh
│   ├── install_pi.sh
│   └── install_qwen.sh
├── install_antigravity.sh -> available/install_antigravity.sh
├── install_claude.sh -> available/install_claude.sh
├── install_codex.sh -> available/install_codex.sh
├── install_copilot.sh -> available/install_copilot.sh
├── install_opencode.sh -> available/install_opencode.sh
├── install_pi.sh -> available/install_pi.sh
└── sync-ollama-models.py
```

### How it works

* `scripts/available/` contains all available install scripts
* The root `scripts/` directory contains enabled scripts (via symlinks)
* During the Docker build, all `*.sh` files in `scripts/` are executed

> Only linked scripts are executed during `docker compose build`.

---

### Enable a script

```bash
ln -s available/install_hermes.sh scripts/install_hermes.sh
```

---

### Disable a script

```bash
rm scripts/install_hermes.sh
```

---

### Example

Enable Gemini CLI and Oh-My-Pi (`omp`):

```bash
ln -s available/install_gemini.sh scripts/install_gemini.sh
ln -s available/install_ohmypi.sh scripts/install_ohmypi.sh
```

Then rebuild:

```bash
docker compose build
```

---

### Notes

* Scripts are executed in alphabetical order
* Use numeric prefixes if ordering matters:

```text
10_install_claude.sh
20_install_codex.sh
```

* Scripts should be idempotent where possible

---

## Volumes & UID/GID Ownership Mapping

The container mounts:

* `/work` → workspace directory (`${WORKSPACE:-./workspace}`)
* `/projects` → additional project repos (`${PROJECTS:-./projects}`, e.g. `~/Projects`)
* `/home/agent` → persistent agent home/config (`./agent_home`)
* `/scripts` → helper scripts (`./scripts`)
* `/docs` → documentation (`./docs`)
* `/tools` → indexing scripts (`./tools`)

Agent-specific directories (`ANTIGRAVITY_DOT_DIR`, `CLAUDE_*`, `CODEX_DOT_DIR`) can also be mounted from outside `./agent_home` via `.env`.

### Host User Mapping & `chown` Flags

On startup, `docker-entrypoint.sh` remaps the container's `agent` user and group to `LOCAL_UID` and `LOCAL_GID` (from `CALLER_UID` / `CALLER_GID` in `.env`) and drops privileges with `gosu agent` so files created in mounted volumes match your host user's ownership without running agents as `root`.

* By default (`CHOWN_AGENT_HOME=false`, `CHOWN_WORK=false`), the entrypoint **never** runs recursive `chown -R` on `/home/agent`, `/work`, or `/projects`. It only fixes top-level directory ownership if Docker auto-created an empty mount target owned by `root` (`UID 0`).
* If you want the entrypoint to recursively `chown -R` `/home/agent` or `/work` on startup, set `CHOWN_AGENT_HOME=true` or `CHOWN_WORK=true` in `.env`.
* `/projects` is never chowned under any flag.

---

## Usage

Inside the container you can:

* run CLI agents (e.g. `agy`, `claude`, `codex`, `copilot`, `opencode`, `pi`)
* use `uv` / `uvx`, `npm` / `npx`, `git`, `gh`, `rg`
* manage projects in `/work` or `/projects`
* use tmux for persistent sessions

---

## Headless CLI authentication

For remote terminals and headless sessions, use device-code / no-browser login flows where available.

### Typical commands

```bash
# Antigravity (detects headless/remote sessions and prints an OAuth URL)
agy

# Codex (device auth flow)
codex login --device-auth
```

### Notes by client

* `agy` (Antigravity): launches an OAuth flow in local browsers or prints an authorization URL in headless/SSH sessions. Use `/config`, `/agents`, or `/logout` inside the TUI.
* `codex`: use `codex login --device-auth` in headless environments.
* other clients (Claude, Copilot, Gemini, OpenCode, Pi, Hermes, Oh-My-Pi, OpenClaw): auth flags may vary by version; check:

```bash
<client> --help
<client> login --help
```

If your local profile/config is mounted (see `ANTIGRAVITY_DOT_DIR`, `CLAUDE_*`, and `CODEX_DOT_DIR` in `.env`), the authenticated session persists across container runs.

---

## Local model backends (WIP)

> 🚧 Work in progress: this section outlines a baseline pattern for connecting agent CLIs to local model servers such as Ollama.

### 1) Start Ollama on the host

Run Ollama locally (outside the container), for example:

```bash
ollama serve
```

By default this listens on `http://localhost:11434`.

### 2) Ensure the container can reach the host

From inside Docker, the host is usually reachable as:

* `host.docker.internal` (Docker Desktop/macOS/Windows)
* Linux may require explicit host-gateway mapping in `docker-compose.yml`

Example Linux-friendly addition:

```yaml
services:
  app:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

### 3) Syncing Ollama models into `pi` (`sync-ollama-models.py`)

For the `pi` coding agent (`@mariozechner/pi-coding-agent`), use the included helper script to fetch models from your Ollama server and interactively enable/disable them in `~/.pi/agent/models.json`:

```bash
python3 /scripts/sync-ollama-models.py --host host.docker.internal --port 11434
```

### 4) Point other clients to the local model endpoint

Each CLI has different config/env flags, but the common pattern is:

```bash
export OLLAMA_HOST=http://host.docker.internal:11434
<client> --help
<client> config --help
```

If a CLI supports OpenAI-compatible base URLs instead of `OLLAMA_HOST`, set that client's `BASE_URL`/endpoint config to `http://host.docker.internal:11434/v1`.

### 5) Quick connectivity check inside the container

```bash
curl -fsS http://host.docker.internal:11434/api/tags
```

If this fails, verify Docker host routing and that Ollama is running on the host.

---

## Notes

* Container runs with interactive TTY enabled
* TERM and color settings are configured for modern terminals
* Designed to work well with tmux and iTerm2

## ⚠️ Security

This container is intended for **local development only**.

It runs with elevated privileges:

* `seccomp:unconfined`
* `CAP_SYS_ADMIN`
* support for tools like `bubblewrap`

### Implications

* Reduced container isolation
* Do **not** run untrusted code
* Potential increased access to the host system

### Use only for

* Local, single-user environments
* Trusted workloads

### Do NOT use for

* Production
* Shared/multi-user systems
* Untrusted code execution

> If stronger isolation is required, remove elevated privileges or run inside a VM.
