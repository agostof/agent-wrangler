# agent-wrangler

A lightweight Docker-based sandbox for running and managing AI agent tooling (e.g. Codex, Claude, Jules) in a controlled, reproducible environment.

## Overview

`agent-wrangler` provides a consistent development/runtime container for trying and using multiple agent CLIs without polluting your host environment. It keeps agent binaries/configuration inside a reproducible Docker setup while still granting the permissions some tools need to function (for example `bubblewrap`-based workflows and elevated container capabilities).

It includes:

* isolated workspace and project directories
* mounted agent configuration (Claude, Codex, etc.)
* interactive terminal support (tmux-friendly)
* reproducible environment via Docker

## Files

* `Dockerfile` – builds the sandbox image
* `docker-compose.yml` – defines the runtime container
* `docker-entrypoint.sh` – container startup logic
* `env.example` – environment variable template
* scripts/ – install scripts for agent tooling

## Getting Started

### 1. Copy environment file

```bash
cp env.example .env
```

Edit `.env` as needed.

---

### 2. Enable desired tools

See Script Configuration below.

---

### 3. Build the container

```bash
docker compose build
```

---

### 4. Start the sandbox

```bash
docker compose run --rm app
```

or:

```bash
docker compose up
```

---

## Script Configuration

The `scripts/` directory controls which tools are installed into the container.

### Structure

```text
scripts/
├── available/
│   ├── install_claude.sh
│   ├── install_codex.sh
│   ├── install_gemini.sh
│   ├── install_jules.sh
│   ├── install_openclaw.sh
│   └── install_opencode.sh
├── install_claude.sh -> available/install_claude.sh
├── install_codex.sh -> available/install_codex.sh
├── install_gemini.sh -> available/install_gemini.sh
├── install_jules.sh -> available/install_jules.sh
└── install_opencode.sh -> available/install_opencode.sh
```

### How it works

* `scripts/available/` contains all available install scripts
* The root `scripts/` directory contains enabled scripts (via symlinks)
* During the Docker build, all `*.sh` files in `scripts/` are executed

> Only linked scripts are executed.

---

### Enable a script

```bash
ln -s available/install_codex.sh scripts/install_codex.sh
```

---

### Disable a script

```bash
rm scripts/install_codex.sh
```

---

### Example

Enable Codex and Claude:

```bash
ln -s available/install_codex.sh scripts/install_codex.sh
ln -s available/install_claude.sh scripts/install_claude.sh
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

## Volumes

The container mounts:

* `/work` → workspace directory
* `/projects` → additional project repos
* `/home/agent` → persistent agent home/config
* `/scripts` → helper scripts

Agent-specific directories (Claude, Codex, etc.) are also mounted via environment variables.

---

## Usage

Inside the container you can:

* run CLI tools (e.g. `codex`, `npm`, `git`)
* manage projects in `/work` or `/projects`
* use tmux for persistent sessions
* execute deployment scripts or SSH workflows

---

## Headless CLI authentication

For remote terminals and headless sessions, use device-code / no-browser login flows where available.

### Typical commands

```bash
# Codex (device auth flow)
codex login --device-auth

# Jules (explicit no-browser flow)
jules login --no-launch-browser
```

### Notes by client

* `codex`: use `codex login --device-auth` in headless environments.
* `jules`: supports `jules login --no-launch-browser` (also echoed by the install script).
* other clients (Claude, Gemini, OpenCode, OpenClaw): auth flags may vary by version; check:

```bash
<client> login --help
```

If your local profile/config is mounted (see `CLAUDE_*` / `CODEX_DOT_DIR` in `.env`), the authenticated session persists across container runs.

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

### 3) Point the client to the local model endpoint

Each CLI has different config/env flags, but the common pattern is:

```bash
export OLLAMA_HOST=http://host.docker.internal:11434
<client> --help
<client> config --help
```

If a CLI supports OpenAI-compatible base URLs instead of `OLLAMA_HOST`, set that client's `BASE_URL`/endpoint config to your local server.

### 4) Quick connectivity check inside the container

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
