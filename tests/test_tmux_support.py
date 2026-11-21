"""Tests for in-container tmux support: connect script options, tmux config, compose settings."""
import os
import pathlib
import shutil
import subprocess
import time
import uuid

import pytest

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CONNECT_SCRIPT = REPO_ROOT / "connect_as_agent_user.sh"
TMUX_CONF = REPO_ROOT / "config" / "tmux.conf"
COMPOSE_FILE = REPO_ROOT / "docker-compose.yml"

SEP = "\x1f"

# Stand-in for the docker CLI: logs every call and simulates the container.
FAKE_DOCKER = r"""#!/usr/bin/env bash
(IFS=$'\x1f'; echo "$*") >> "$FAKE_DOCKER_LOG"
case "$1" in
  ps) printf '%s\n' ${FAKE_PS-agentsandbox} ;;
  exec)
    shift
    args=("$@")
    if [[ " ${args[*]} " == *" command -v tmux"* ]]; then exit "${FAKE_HAS_TMUX:-0}"; fi
    if [[ " ${args[*]} " == *" printenv AW_TMUX_PREFIX"* ]]; then
      [ -n "${FAKE_CONTAINER_PREFIX:-}" ] && { echo "$FAKE_CONTAINER_PREFIX"; exit 0; }
      exit 1
    fi
    exit 0 ;;
esac
"""


@pytest.fixture
def fake_docker(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    docker = bin_dir / "docker"
    docker.write_text(FAKE_DOCKER)
    docker.chmod(0o755)
    log = tmp_path / "docker.log"

    def run(*args, env_extra=None):
        env = {k: v for k, v in os.environ.items() if k not in ("TMUX", "AW_SESSION")}
        env.update({"PATH": f"{bin_dir}:{env['PATH']}", "FAKE_DOCKER_LOG": str(log)})
        env.update(env_extra or {})
        if log.exists():
            log.unlink()
        res = subprocess.run(
            ["bash", str(CONNECT_SCRIPT), *args], capture_output=True, text=True, env=env
        )
        calls = [line.split(SEP) for line in log.read_text().splitlines()] if log.exists() else []
        return res, calls

    return run


def final_exec(calls):
    """The last docker call is the interactive exec the script hands over to."""
    assert calls, "docker was never called"
    return calls[-1]


def tmux_cmd(call):
    return call[call.index("tmux"):]


def test_default_opens_bash_shell(fake_docker):
    res, calls = fake_docker()
    assert res.returncode == 0
    assert final_exec(calls) == ["exec", "-it", "--user", "agent", "agentsandbox", "bash"]


def test_tmux_attaches_or_creates_default_session(fake_docker):
    res, calls = fake_docker("--tmux")
    assert res.returncode == 0
    call = final_exec(calls)
    assert call[:5] == ["exec", "-it", "--user", "agent", "agentsandbox"]
    assert tmux_cmd(call) == ["tmux", "new-session", "-A", "-s", "agents"]


def test_cc_uses_iterm2_control_mode(fake_docker):
    res, calls = fake_docker("--cc")
    assert tmux_cmd(final_exec(calls)) == ["tmux", "-CC", "new-session", "-A", "-s", "agents"]


def test_session_name_from_flag_and_env(fake_docker):
    _, calls = fake_docker("--tmux", "--session", "work")
    assert tmux_cmd(final_exec(calls))[-1] == "work"
    _, calls = fake_docker("--tmux", env_extra={"AW_SESSION": "fromenv"})
    assert tmux_cmd(final_exec(calls))[-1] == "fromenv"


def test_prefix_is_set_on_the_session(fake_docker):
    _, calls = fake_docker("--cc", "--prefix", "C-a")
    assert tmux_cmd(final_exec(calls)) == [
        "tmux", "-CC", "new-session", "-A", "-s", "agents",
        ";", "set-option", "prefix", "C-a", ";", "bind-key", "C-a", "send-prefix",
    ]


def test_nested_in_host_tmux_defaults_to_c_a(fake_docker):
    res, calls = fake_docker("--tmux", env_extra={"TMUX": "/tmp/tmux-1000/default,1,0"})
    assert res.returncode == 0
    assert "prefix" in tmux_cmd(final_exec(calls))
    assert tmux_cmd(final_exec(calls))[tmux_cmd(final_exec(calls)).index("prefix") + 1] == "C-a"
    assert "C-a" in res.stderr


@pytest.mark.parametrize(
    "args,env_extra,expected_prefix",
    [
        (["--tmux", "--prefix", "C-b"], {}, "C-b"),          # explicit flag wins
        (["--tmux"], {"FAKE_CONTAINER_PREFIX": "C-s"}, None),  # .env TMUX_PREFIX wins
        (["--cc"], {}, None),                                  # -CC is not nested
    ],
)
def test_nested_auto_prefix_respects_explicit_choices(fake_docker, args, env_extra, expected_prefix):
    env = {"TMUX": "/tmp/tmux-1000/default,1,0", **env_extra}
    _, calls = fake_docker(*args, env_extra=env)
    cmd = tmux_cmd(final_exec(calls))
    if expected_prefix is None:
        assert "set-option" not in cmd
    else:
        assert cmd[cmd.index("prefix") + 1] == expected_prefix


def test_container_argument_and_fallback(fake_docker):
    _, calls = fake_docker("--tmux", "mybox", env_extra={"FAKE_PS": "mybox"})
    assert final_exec(calls)[4] == "mybox"
    # `docker compose run` containers get generated names
    _, calls = fake_docker("--tmux", env_extra={"FAKE_PS": "agentsandbox-app-run-1a2b"})
    assert final_exec(calls)[4] == "agentsandbox-app-run-1a2b"


def test_missing_tmux_gives_actionable_error(fake_docker):
    res, calls = fake_docker("--tmux", env_extra={"FAKE_HAS_TMUX": "1"})
    assert res.returncode == 1
    assert "install_tmux.sh" in res.stderr
    assert not any("new-session" in c for c in calls)


def test_bad_options(fake_docker):
    assert fake_docker("--bogus")[0].returncode == 2
    assert fake_docker("--prefix")[0].returncode == 2
    res, _ = fake_docker("--help")
    assert res.returncode == 0 and "--cc" in res.stdout


# --- config/tmux.conf against a real tmux --------------------------------------

needs_tmux = pytest.mark.skipif(shutil.which("tmux") is None, reason="tmux not installed")


@pytest.fixture
def tmux_server(tmp_path):
    sockets = []

    def start(**env_vars):
        sock = f"awtest-{uuid.uuid4().hex[:8]}"
        sockets.append(sock)
        env = {**os.environ, "HOME": str(tmp_path), **env_vars}
        env.pop("TMUX", None)
        subprocess.run(
            ["tmux", "-L", sock, "-f", str(TMUX_CONF), "new-session", "-d", "-s", "agents"],
            check=True, env=env,
        )
        time.sleep(0.3)

        def show(option):
            return subprocess.run(
                ["tmux", "-L", sock, "show", "-gv", option], capture_output=True, text=True
            ).stdout.strip()

        return show

    yield start
    for sock in sockets:
        subprocess.run(["tmux", "-L", sock, "kill-server"], capture_output=True)


@needs_tmux
def test_tmux_conf_defaults(tmux_server):
    show = tmux_server(AW_TMUX_PREFIX="", AW_TMUX_RESURRECT="false")
    assert show("prefix") == "C-b"
    assert show("default-terminal") == "tmux-256color"
    assert show("set-clipboard") == "on"
    assert show("@continuum-restore") == ""


@needs_tmux
def test_tmux_conf_prefix_from_env(tmux_server):
    show = tmux_server(AW_TMUX_PREFIX="C-a", AW_TMUX_RESURRECT="false")
    assert show("prefix") == "C-a"


@needs_tmux
def test_tmux_conf_resurrect_opt_in(tmux_server):
    show = tmux_server(AW_TMUX_PREFIX="", AW_TMUX_RESURRECT="true")
    assert show("@continuum-restore") == "on"
    assert "claude --continue" in show("@resurrect-processes")


# --- docker-compose.yml ------------------------------------------------------------


def _compose_config(env_extra):
    if shutil.which("docker") is None:
        pytest.skip("docker CLI not installed")
    env = {"PATH": os.environ["PATH"], "HOME": os.environ.get("HOME", "/tmp"), **env_extra}
    res = subprocess.run(
        ["docker", "compose", "-f", str(COMPOSE_FILE), "--env-file", os.devnull, "config"],
        capture_output=True, text=True, env=env,
    )
    if res.returncode != 0 and "compose" in res.stderr and "not a docker command" in res.stderr:
        pytest.skip("docker compose plugin not installed")
    assert res.returncode == 0, res.stderr
    return res.stdout


def test_compose_defaults_keep_previous_behavior():
    out = _compose_config({})
    assert 'restart: "no"' in out
    assert "target: /etc/tmux.conf" in out and "read_only: true" in out


def test_compose_optional_settings():
    out = _compose_config(
        {"RESTART_POLICY": "unless-stopped", "TMUX_PREFIX": "C-a", "TMUX_RESURRECT": "true"}
    )
    assert "restart: unless-stopped" in out
    assert "AW_TMUX_PREFIX: C-a" in out
    assert 'AW_TMUX_RESURRECT: "true"' in out
