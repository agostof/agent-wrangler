import importlib.util
import os
import pathlib
import subprocess
import pytest

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SYNC_OLLAMA_SCRIPT = REPO_ROOT / "scripts" / "sync-ollama-models.py"

spec = importlib.util.spec_from_file_location("sync_ollama_models", SYNC_OLLAMA_SCRIPT)
sync_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync_mod)

SHELL_SCRIPTS = sorted(p for p in REPO_ROOT.rglob("*.sh") if ".git" not in p.parts)


@pytest.mark.parametrize("sh_path", SHELL_SCRIPTS, ids=lambda p: str(p.relative_to(REPO_ROOT)))
def test_shell_script_syntax(sh_path: pathlib.Path):
    res = subprocess.run(["bash", "-n", str(sh_path)], capture_output=True, text=True)
    assert res.returncode == 0, f"Syntax error in {sh_path}: {res.stderr}"


def test_jules_removed_and_expected_agents_enabled():
    scripts_dir = REPO_ROOT / "scripts"
    avail_dir = scripts_dir / "available"

    assert not (scripts_dir / "install_jules.sh").exists()
    assert not (avail_dir / "install_jules.sh").exists()

    expected_enabled = {
        "install_antigravity.sh",
        "install_claude.sh",
        "install_codex.sh",
        "install_copilot.sh",
        "install_opencode.sh",
        "install_pi.sh",
        "install_tmux.sh",
    }
    actual_symlinks = {p.name for p in scripts_dir.iterdir() if p.is_symlink()}
    assert actual_symlinks == expected_enabled

    for name in actual_symlinks:
        link_path = scripts_dir / name
        assert link_path.resolve().exists(), f"Broken symlink: {link_path}"
        assert os.readlink(link_path) == f"available/{name}"


@pytest.mark.parametrize(
    "optional_script",
    [
        "install_aider.sh",
        "install_gemini.sh",
        "install_goose.sh",
        "install_hermes.sh",
        "install_ohmypi.sh",
        "install_openclaw.sh",
        "install_qwen.sh",
    ],
)
def test_optional_agent_scripts_present(optional_script: str):
    avail_dir = REPO_ROOT / "scripts" / "available"
    assert (avail_dir / optional_script).is_file()


def test_sync_ollama_models_helpers():
    assert sync_mod.build_url("localhost", "11434") == "http://localhost:11434/v1"
    cfg = {"providers": {"ollama": {"baseUrl": "http://myhost:11434/v1/", "apiKey": "custom"}}}
    assert sync_mod.get_provider_url(cfg, "ollama") == "http://myhost:11434/v1/models"

    provider_obj = sync_mod.build_provider_config(
        "ollama", cfg, "myhost", "11434", {"qwen2.5-coder:7b", "llama3.1:8b"}
    )
    assert provider_obj["baseUrl"] == "http://myhost:11434/v1"
    assert provider_obj["apiKey"] == "custom"
    assert provider_obj["models"] == [{"id": "llama3.1:8b"}, {"id": "qwen2.5-coder:7b"}]
