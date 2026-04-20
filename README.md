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

## Notes

* Container runs with interactive TTY enabled
* TERM and color settings are configured for modern terminals
* Designed to work well with tmux and iTerm2

