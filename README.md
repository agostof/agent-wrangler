# agent-wrangler

A lightweight Docker-based sandbox for running and managing AI agent tooling (e.g. Codex, Claude, Jules) in a controlled, reproducible environment.

## Overview

`agent-wrangler` provides a consistent development/runtime container with:

* isolated workspace and project directories
* mounted agent configuration (Claude, Codex, etc.)
* interactive terminal support (tmux-friendly)
* reproducible environment via Docker

## Files

* `Dockerfile` – builds the sandbox image
* `docker-compose.yml` – defines the runtime container
* `docker-entrypoint.sh` – container startup logic
* `env.example` – environment variable template

## Getting Started

### 1. Copy environment file

```bash
cp env.example .env
```

Edit `.env` as needed.

---

### 2. Build the container

```bash
docker compose build
```

---

### 3. Start the sandbox

```bash
docker compose run --rm app
```

or:

```bash
docker compose up
```

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

## Notes

* Container runs with interactive TTY enabled
* TERM and color settings are configured for modern terminals
* Designed to work well with tmux and iTerm2

