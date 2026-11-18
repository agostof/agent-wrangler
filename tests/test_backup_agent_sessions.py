import importlib.util
import json
import pathlib
import subprocess
import sys
import pytest

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
BACKUP_SCRIPT = REPO_ROOT / "tools" / "backup-agent-sessions.py"

spec = importlib.util.spec_from_file_location("backup_agent_sessions", BACKUP_SCRIPT)
backup_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backup_mod)


@pytest.mark.parametrize(
    "raw_input,expected",
    [
        (
            "<USER_REQUEST>\nHello world\n</USER_REQUEST>\n<ADDITIONAL_METADATA>...</ADDITIONAL_METADATA>",
            "Hello world",
        ),
        ("<SYSTEM_MESSAGE>\nTask finished\n</SYSTEM_MESSAGE>", ""),
        ("Plain text prompt", "Plain text prompt"),
        ("", ""),
    ],
)
def test_clean_user_content(raw_input: str, expected: str):
    assert backup_mod.clean_user_content(raw_input) == expected


def test_end_to_end_backup_and_viewer_generation(tmp_path: pathlib.Path):
    fake_home = tmp_path / "home"
    out_dir = tmp_path / "out"

    # 1. Create fake Antigravity conversation
    agy_logs = fake_home / ".gemini/antigravity-cli/brain/conv-123/.system_generated/logs"
    agy_logs.mkdir(parents=True)
    steps = [
        {
            "step_index": 0,
            "source": "USER_EXPLICIT",
            "type": "USER_INPUT",
            "created_at": "2026-11-18T00:00:00Z",
            "content": "<USER_REQUEST>\nFix the entrypoint script</USER_REQUEST>",
        },
        {
            "step_index": 1,
            "source": "MODEL",
            "type": "PLANNER_RESPONSE",
            "created_at": "2026-11-18T00:00:05Z",
            "thinking": "Checking docker-entrypoint.sh",
            "tool_calls": [{"name": "read_file", "args": {"Path": "/opt/agent/docker-entrypoint.sh"}}],
            "content": "I have updated `docker-entrypoint.sh`.",
        },
    ]
    (agy_logs / "transcript_full.jsonl").write_text(
        "\n".join(json.dumps(s) for s in steps) + "\n"
    )

    # 2. Create fake Claude & Pi session logs
    claude_dir = fake_home / ".claude/projects/my-project"
    claude_dir.mkdir(parents=True)
    (claude_dir / "session-1.jsonl").write_text(
        json.dumps({"role": "user", "content": "Hello Claude", "timestamp": "2026-11-18T01:00:00Z"}) + "\n"
    )

    pi_dir = fake_home / ".pi/agent/sessions"
    pi_dir.mkdir(parents=True)
    (pi_dir / "pi-session.jsonl").write_text(
        json.dumps({"role": "user", "text": "Hello Pi </script>", "createdAt": "2026-11-18T01:05:00Z"}) + "\n"
    )

    # Run CLI script
    res = subprocess.run(
        [sys.executable, str(BACKUP_SCRIPT), "--home", str(fake_home), "--out", str(out_dir)],
        capture_output=True,
        text=True,
        check=True,
    )
    summary = json.loads(res.stdout)
    assert summary["status"] == "ok"
    assert summary["total_sessions"] == 3

    # Verify output files exist
    assert (out_dir / "index.html").exists()
    assert (out_dir / "SUMMARY.md").exists()
    assert (out_dir / "antigravity/conv-123/conversation.md").exists()
    assert (out_dir / "antigravity/conv-123/transcript_full.jsonl").exists()
    assert (out_dir / "claude/my-project/session-1.jsonl").exists()
    assert (out_dir / "pi/pi-session.jsonl").exists()

    # Verify Markdown content
    conv_md = (out_dir / "antigravity/conv-123/conversation.md").read_text()
    assert "Fix the entrypoint script" in conv_md
    assert "I have updated `docker-entrypoint.sh`." in conv_md

    # Verify HTML escapes closing </script> tags properly
    html_text = (out_dir / "index.html").read_text()
    assert "Hello Pi </script>" not in html_text
    assert "Hello Pi <\\/script>" in html_text
