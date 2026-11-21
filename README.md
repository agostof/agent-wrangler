# agent-wrangler

## Overview

A Docker container (`agentsandbox`) for installing and running AI coding agent CLIs, e.g. Antigravity (`agy`), Claude Code, Codex, Copilot, OpenCode, and Pi, without installing them on the host.

### Uses

* Try a new agent CLI without installing it on the host.
* Run several agents side by side, or compare them on the same repository.
* Run long agent sessions on a remote Linux host, and reconnect to them over SSH with tmux.
* Let agents work on a project without access to the rest of your files.
* Use local or self-hosted models (e.g. Ollama, Strata) with the agents that support them.

### Contents

The container includes:
* Node 22 (`nvm`), Python 3, `uv` / `uvx`, `git`, `gh`, `rg`, `tmux`, and `bubblewrap`
* install scripts for 13 agent CLIs; 6 are enabled by default (see [Script configuration](#script-configuration))
* your host `UID:GID` mapped to the container's `agent` user, so files written in mounted directories are owned by you, not `root`
* helper tools in `/tools` and agent workflows ("skills") in `/docs`

Agent CLIs change often and the install scripts pull the latest versions, so expect an install script to break from time to time.

> Note: This is meant for personal development use on a machine you control: your own computer, or a Linux host you connect to over SSH. Please read the [Security](#security) section before running agents unattended.

## Why agent-wrangler?

Coding agents now run commands, edit files, and install packages on their own, often for long stretches without asking for approval. Each agent has its own controls for this: approval prompts, permission settings, and in some cases a sandbox for the commands it runs (e.g. `bubblewrap` or Seatbelt). These controls differ between agents, change between versions, and are set by the agent's vendor. The agent itself still runs with your user's access to the host.

agent-wrangler adds a layer that is the same for every agent and that you control:
* **What the agents can see.** Only the mounted directories (workspace, projects, and agent home) are available inside the container. The rest of your files, including SSH keys and cloud credentials, are out of the agents' reach. Mount only the projects the agents need.
* **What the agents can access.** Agents don't get your git, SSH, or cloud credentials. They can only use services you log into from inside the container.
* **What is installed.** Agents and tools are added with install scripts, and live in the image instead of on the host. Rebuild the image to update them, or delete it to remove them. If an agent breaks the container's setup, recreate the container.
* **What is kept.** Logins, settings, and session history are kept in the agent home directory (`./agent_home`), or in the agent config directories set in `.env`. Session history from all agents can be collected and reviewed with the backup tool.\*
* **How the agents run.** Every agent gets the same Linux environment, tools, and helper scripts, on any host. Agents can run side by side in tmux sessions, locally or on a remote host, and can be compared on the same repository.

\* *The backup tool fully converts Antigravity sessions only. Other agents' sessions are copied as they are, and some agents are not supported yet. See [Backing up agent sessions](#backing-up-agent-sessions) for details.*

This layer is currently limited to the filesystem. Network access is not restricted, and the container runs with elevated privileges so that the agents' own sandboxes work inside it. See [Security](#security) for details.

## Quick start

1. Copy and edit the environment file.
```bash
cp env.example .env
# set CALLER_UID / CALLER_GID to the output of `id -u` / `id -g`
# set WORKSPACE and PROJECTS, and the agent config paths (CLAUDE_*, CODEX_DOT_DIR, ANTIGRAVITY_DOT_DIR)
vim .env
```
The agent config paths in `env.example` are only examples; change or remove them. Also note that `PROJECTS` is set to `~/Projects`, so the agents will see every project in it. Point it to a smaller directory if needed.

2. Create the directories you are mounting. If a path in `.env` does not exist, Docker creates it as a `root`-owned **directory**. For `.claude.json` this breaks Claude Code, because Claude expects a file there.
```bash
mkdir -p workspace projects agent_home/.claude agent_home/.codex \
         agent_home/.local/state/claude agent_home/.gemini/antigravity-cli
# Claude Code expects a file here, not a directory
[ -e agent_home/.claude.json ] || echo '{}' > agent_home/.claude.json
```

3. Enable the agents you want (optional, see [Script configuration](#script-configuration)) and build the image.
```bash
docker compose build    # or ./build.sh
```

4. Start the container. For a one-off shell:
```bash
docker compose run --rm app
```
or keep it running in the background and connect to it:
```bash
docker compose up -d
./connect_as_agent_user.sh          # bash shell
./connect_as_agent_user.sh --cc     # tmux session, iTerm2 integration (see tmux sessions)
```

## Script configuration

The `scripts/` directory controls what is installed into the image. Install scripts live in `scripts/available/`; a script is enabled by creating a symlink to it in `scripts/`. During `docker compose build`, every `*.sh` in `scripts/` runs as `root`, in alphabetical order.

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
│   ├── install_qwen.sh
│   └── install_tmux.sh
├── install_antigravity.sh -> available/install_antigravity.sh
├── install_claude.sh -> available/install_claude.sh
├── install_codex.sh -> available/install_codex.sh
├── install_copilot.sh -> available/install_copilot.sh
├── install_opencode.sh -> available/install_opencode.sh
├── install_pi.sh -> available/install_pi.sh
├── install_tmux.sh -> available/install_tmux.sh
└── sync-ollama-models.py
```

For example, to enable Gemini CLI and Oh-My-Pi (`omp`) and disable Pi:
```bash
ln -s available/install_gemini.sh scripts/install_gemini.sh
ln -s available/install_ohmypi.sh scripts/install_ohmypi.sh
rm scripts/install_pi.sh
docker compose build
```

Some notes:
* Use numeric prefixes if the order matters, e.g. `10_install_claude.sh`, `20_install_codex.sh`.
* Scripts should be idempotent where possible.
* You can add your own scripts the same way.
* To update the agents, rebuild the image. The agents' own auto-updaters might fail, because global `npm` packages are installed in a `root`-owned directory.

## Volumes and file ownership

The container mounts:
* `/work` → workspace directory (`WORKSPACE`, default `./workspace`)
* `/projects` → additional project repos (`PROJECTS`, default `./projects`)
* `/home/agent` → agent home: configs, logins, caches, shell history (`./agent_home`)
* `/scripts`, `/docs`, `/tools` → the same directories from this repo
* `/etc/tmux.conf` → [config/tmux.conf](config/tmux.conf) (read-only)

The Claude, Codex, and Antigravity config directories can also be mounted from outside `./agent_home` by setting `CLAUDE_DOT_DIR`, `CLAUDE_CONFIG`, `CLAUDE_STATE_DIR`, `CODEX_DOT_DIR`, and `ANTIGRAVITY_DOT_DIR` in `.env`. With those mounted, logins persist across rebuilds.

On startup, [docker-entrypoint.sh](docker-entrypoint.sh) changes the `agent` user and group IDs to `CALLER_UID` / `CALLER_GID`, gives `agent` passwordless `sudo`, and then runs your command as `agent` (via `gosu`).

The entrypoint only fixes the owner of a few top-level directories, and only if they are owned by `root`, e.g. when Docker just created them. Set `CHOWN_AGENT_HOME=true` or `CHOWN_WORK=true` in `.env` to recursively `chown` `/home/agent` or `/work` on startup. `/projects` is never changed.

*Technical Note.* If your host IDs are not `1000:1000` (the image default), the `usermod` call that changes the user ID also changes the owner of files under `/home/agent` that belong to the old ID. This is how `usermod` works and is independent of the `CHOWN_*` settings.

## Using the container

Inside the container you can:
* run the agent CLIs you enabled (by default `agy`, `claude`, `codex`, `copilot`, `opencode`, `pi`)
* use `uv` / `uvx`, `npm` / `npx`, `git`, `gh`, `rg`
* work on projects in `/work` or `/projects`
* install extra packages with `sudo apt-get install ...` (these are lost when the container is recreated; add an install script to keep them)

### tmux sessions

There are two ways to use tmux, and they can be combined.

**tmux on the host.** Run tmux on the host, e.g. after connecting with iTerm2 over SSH. Start the container in the first tmux window, then connect to it from each additional window to run another agent:
```bash
# first window
docker compose run --rm app
# each additional window
./connect_as_agent_user.sh
```
If tmux-resurrect is used on the host, the layout survives a reboot, but the container has to be started again in the first window. Please note that exiting the shell in the first window stops a `run --rm` container and ends the other sessions too; use `docker compose up -d` to avoid this.

**tmux inside the container.** Start the container in the background and attach to a tmux session that lives inside it:
```bash
docker compose up -d
./connect_as_agent_user.sh --tmux    # plain tmux
./connect_as_agent_user.sh --cc      # iTerm2 integration (tmux -CC): tmux windows open as iTerm2 tabs

# from another machine
ssh -t linuxhost '~/agent-wrangler/connect_as_agent_user.sh --cc'
```
Both commands attach to the `agents` session and create it if needed (use `--session NAME` for a different one). The agents keep running if you detach, close iTerm2, or lose the SSH connection; run the same command again to reconnect. This also lets you:
* start agents in the background, e.g. `docker exec -u agent agentsandbox tmux new -d -s job1 'codex exec "..."'`, and check on them later with `tmux capture-pane -pt job1`
* have agents use tmux themselves, e.g. for dev servers or long builds
* watch a session from a second terminal with `tmux attach -r -t agents` (read-only)

> Note: Always connect as `agent` (the connect script does). `docker exec` without `-u agent` runs as `root` and starts a separate, empty tmux server.

**Prefix key.** The default prefix is `C-b`. This matters when the container's tmux runs inside the host's tmux, since both would use the same key:
* `--prefix C-a` sets the prefix for that session only.
* `TMUX_PREFIX=C-a` in `.env` sets the default for all sessions.
* If you run `--tmux` from inside a host tmux and neither of the above is set, the script picks `C-a` and prints a message. Use `--prefix C-b` to keep `C-b`.
* With `--cc` the prefix is rarely needed, so it is left as is.

**Keeping sessions after a restart (optional).** Two settings in `.env`, both off by default:
```bash
# restart the `up -d` container after a Docker or host restart (default: no)
RESTART_POLICY=unless-stopped
# save tmux sessions every 15 minutes and restore them the next time tmux starts (default: false)
TMUX_RESURRECT=true
```
`TMUX_RESURRECT` loads [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum), which are installed with tmux (pinned versions). The saves go to `./agent_home/.local/share/tmux/resurrect`. After a restore, Claude Code and Codex are restarted with `claude --continue` and `codex resume --last`; other agents come back as plain shells. This is best effort; edit `@resurrect-processes` in [config/tmux.conf](config/tmux.conf) to change it. You can also save and restore manually with `prefix + C-s` and `prefix + C-r`.

Changes to `TMUX_PREFIX` and `TMUX_RESURRECT` apply to new tmux servers: recreate the container (`docker compose up -d`) or run `tmux kill-server` inside it. Personal tmux settings go in `./agent_home/.tmux.conf`, which is loaded after `/etc/tmux.conf`.

tmux and the plugins add about 2 MB to the image. To leave them out, `rm scripts/install_tmux.sh` and rebuild.

### Backing up agent sessions

```bash
python3 /tools/backup-agent-sessions.py --out /work/agent-session-backups
```
This copies session files from Antigravity, Claude Code, Codex, Pi / Oh-My-Pi, OpenCode, Hermes, Goose, and Gemini CLI into one directory, and writes an `index.html` viewer and a `SUMMARY.md` inventory.

Current limitations:
* Only Antigravity sessions are converted to readable Markdown (`conversation.md`). For the other agents the files are copied as they are, and the viewer shows their JSON lines; for Claude Code this is mostly raw JSON.
* The viewer shows the first 500 lines of each file. The copied files are complete.
* Pi and Oh-My-Pi files go to the same `pi/` folder, so files with the same name overwrite each other.
* Agents that keep sessions in SQLite or other formats are not included.
* Every run copies everything again. Transcripts can contain secrets, so treat the backup folder accordingly.

### Indexing a repository

```bash
cd /work/my-repo
bash /tools/index-repo.sh .claude   # output directory; defaults to .claude
```
Creates `index/text/`, `index/json/`, and `index/markdown/` with source files, definitions, imports, architecture, and TODO/FIXME annotations. It uses `rg` / `grep` patterns, not a parser, for Python, Java, JavaScript/TypeScript, and shell. Use the output as a navigation aid.

> Note: The JSON files are built without escaping, so a file can be invalid JSON when the matched text contains quotes. The text and Markdown files are not affected.

See [tools/README-INDEX.md](tools/README-INDEX.md) for details.

### Skills

[docs/skills/](docs/skills/) contains agent workflows written in Markdown (currently [codebase-inspection.md](docs/skills/codebase-inspection.md)). Agents do not load them automatically; point the agent to the file in your prompt, or reference it from the project's `AGENTS.md` / `CLAUDE.md`.

## Headless CLI authentication

When the container runs on a remote host over SSH, or anywhere else without a browser, use the device-code / no-browser login flows where available.
```bash
# Antigravity: prints an authorization URL when no browser is available
agy

# Codex: device auth flow
codex login --device-auth
```
* `agy`: use `/config`, `/agents`, or `/logout` inside the TUI.
* Other clients (Claude, Copilot, Gemini, OpenCode, Pi, Hermes, Oh-My-Pi, OpenClaw): the auth flags vary by version; check `<client> --help` or `<client> login --help`.

Logins are kept in the agent home or in the config directories mounted from `.env`, so they persist across container runs.

## Local and self-hosted model backends (WIP)

> 🚧 Work in progress: a basic setup for using a local Ollama server from the container.

In this section, "the host" is the machine running Docker. When the container runs on a remote Linux host, the model server has to run on that host, or be reachable from it, not on the computer you connect from.

1. Start Ollama on the host. By default it listens on `http://localhost:11434`.
```bash
ollama serve
```

2. Make the host reachable from the container. Docker Desktop (macOS/Windows) provides `host.docker.internal`. On Linux, the provided `docker-compose.yml` does not include the host mapping yet; add it, e.g. in a `docker-compose.override.yml`:
```yaml
services:
  app:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

3. Check the connection from inside the container.
```bash
curl -fsS http://host.docker.internal:11434/api/tags
```

4. For `pi`, use the included script to list the Ollama models and choose which ones to enable in `~/.pi/agent/models.json` (a backup of the file is made first):
```bash
python3 /scripts/sync-ollama-models.py --host host.docker.internal --port 11434
```

5. Other clients need to be configured by hand. Most accept either `OLLAMA_HOST=http://host.docker.internal:11434` or an OpenAI-compatible base URL, `http://host.docker.internal:11434/v1`. Other model providers, e.g. Strata, can be used the same way if the agent supports them.

## Files

* `Dockerfile`, `docker-compose.yml`, `build.sh`: image and container definition
* `docker-entrypoint.sh`: user ID mapping and startup
* `connect_as_agent_user.sh`: open a shell or a tmux session in the running container (`--help` for options)
* `env.example`: settings template
* `config/tmux.conf`: tmux defaults for the container
* `scripts/`: install scripts and `sync-ollama-models.py`
* `tools/`: repository indexer and session backup
* `docs/`: documentation rules and skills
* `tests/`: tests for the scripts; run with `python3 -m pytest tests`

## Notes

* The image is not version pinned (Ubuntu base image, Node 22.x, `uv`, and the agent CLIs all install their latest versions), so two builds on different days might differ. The tmux plugins and `nvm` are pinned.
* `docker compose up` uses the fixed container name `agentsandbox`, so only one of these containers can run at a time.

## Security

This container is intended for **personal development use**, on a machine you control (your own computer or a Linux host you access over SSH), with code and repositories you trust. You should be the only user with access to Docker on that host, since anyone who can run `docker` can open a shell in the container and read its mounts, including the agents' logins and tokens.

It limits what the agents can see on disk: only the mounted directories are visible, not the rest of the host (e.g. `~/.ssh`, `~/.aws`, browser profiles). It is **not** a strong isolation boundary:
* It runs with `seccomp:unconfined` and `CAP_SYS_ADMIN`, so tools like `bubblewrap` work inside it, and the `agent` user has passwordless `sudo`. An agent can become `root` in a container with elevated privileges.
* Network access is not restricted.
* Everything mounted is readable by the agents, including agent logins and tokens (e.g. Claude, Codex, `gh`) and any `.env` files or secrets under `/projects`.
* `/scripts`, `/docs`, and `/tools` are mounted read-write, so an agent can modify this repo's scripts.

Do **not** use it for production, shared or multi-user systems, untrusted code, or unattended runs where you rely on the container to contain an agent.

> If you need stronger isolation, remove `SYS_ADMIN`, `seccomp:unconfined`, and the `sudo` rule (and turn off the agents' own sandboxes instead), mount only the project you are working on, or run the container inside a VM.
