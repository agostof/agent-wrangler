#!/usr/bin/env python3
"""
Multi-Agent Session Backup & Offline Viewer Generator for agent-wrangler.

Scans the agent home directory ($HOME, e.g. /home/agent) for session histories
and conversation logs across supported coding agents:
  - Google Antigravity (~/.gemini/antigravity-cli/brain/)
  - Claude Code        (~/.claude/projects/, ~/.claude/history.jsonl)
  - OpenAI Codex       (~/.codex/sessions/, ~/.codex/history.jsonl)
  - Pi / Oh-My-Pi      (~/.pi/agent/sessions/, ~/.omp/sessions/)
  - OpenCode           (~/.local/share/opencode/)
  - Gemini CLI         (~/.gemini/tmp/)
  - Hermes Agent       (~/.hermes/sessions/, ~/.local/share/hermes/)
  - Block Goose        (~/.local/share/goose/sessions/)

Produces:
  <out_dir>/
    ├── index.html          # Self-contained offline browser viewer across all backed-up sessions
    ├── SUMMARY.md          # Markdown inventory of all backed-up agent sessions
    ├── antigravity/        # Raw JSONL + rendered conversation.md & conversation.html per session
    ├── claude/             # Raw JSONL + rendered Markdown transcripts
    ├── codex/              # Raw JSONL + rendered Markdown transcripts
    ├── pi/                 # Raw session logs + rendered Markdown transcripts
    └── ...

Usage:
  python3 /tools/backup-agent-sessions.py [--home /home/agent] [--out /work/agent-backups]
"""

import argparse
import datetime
import html
import json
import os
import pathlib
import re
import shutil


AGENT_SOURCES = [
    {
        "id": "antigravity",
        "name": "Google Antigravity (agy)",
        "paths": [".gemini/antigravity-cli/brain"],
        "kind": "antigravity_brain",
    },
    {
        "id": "claude",
        "name": "Claude Code",
        "paths": [".claude/projects", ".claude/history.jsonl"],
        "kind": "jsonl_tree",
    },
    {
        "id": "codex",
        "name": "OpenAI Codex",
        "paths": [".codex/sessions", ".codex/history.jsonl"],
        "kind": "jsonl_tree",
    },
    {
        "id": "pi",
        "name": "Pi / Oh-My-Pi",
        "paths": [".pi/agent/sessions", ".omp/sessions"],
        "kind": "jsonl_tree",
    },
    {
        "id": "opencode",
        "name": "OpenCode",
        "paths": [".local/share/opencode/project", ".local/share/opencode/storage"],
        "kind": "jsonl_tree",
    },
    {
        "id": "hermes",
        "name": "Hermes Agent",
        "paths": [".hermes/sessions", ".local/share/hermes"],
        "kind": "jsonl_tree",
    },
    {
        "id": "goose",
        "name": "Block Goose",
        "paths": [".local/share/goose/sessions"],
        "kind": "jsonl_tree",
    },
    {
        "id": "gemini",
        "name": "Gemini CLI",
        "paths": [".gemini/tmp"],
        "kind": "jsonl_tree",
    },
]


def clean_user_content(raw: str) -> str:
    if not raw:
        return ""
    m = re.search(r"<USER_REQUEST>\s*(.*?)\s*</USER_REQUEST>", raw, flags=re.S)
    if m:
        return m.group(1).strip()
    if "<SYSTEM_MESSAGE>" in raw:
        return ""
    return raw.strip()


def parse_antigravity_brain(brain_dir: pathlib.Path, dest_root: pathlib.Path) -> list[dict]:
    items = []
    if not brain_dir.exists():
        return items

    for conv_dir in sorted(brain_dir.iterdir()):
        if not conv_dir.is_dir():
            continue
        conv_id = conv_dir.name
        logs_dir = conv_dir / ".system_generated/logs"
        full_jsonl = logs_dir / "transcript_full.jsonl"
        compact_jsonl = logs_dir / "transcript.jsonl"
        src_jsonl = full_jsonl if full_jsonl.exists() else compact_jsonl
        if not src_jsonl.exists():
            continue

        out_conv_dir = dest_root / conv_id
        out_conv_dir.mkdir(parents=True, exist_ok=True)
        for f in [compact_jsonl, full_jsonl]:
            if f.exists():
                shutil.copy2(f, out_conv_dir / f.name)

        steps = []
        for line in src_jsonl.read_text(errors="replace").splitlines():
            if line.strip():
                try:
                    steps.append(json.loads(line))
                except Exception:
                    pass

        messages = []
        md_lines = [f"# Antigravity Session `{conv_id}`", ""]
        first_prompt = ""
        created_at = ""

        for st in steps:
            stype = st.get("type", "")
            source = st.get("source", "")
            ts = st.get("created_at", "")
            if not created_at and ts:
                created_at = ts
            content = st.get("content", "")
            thinking = st.get("thinking", "")
            tool_calls = st.get("tool_calls", [])

            if stype == "USER_INPUT" and source == "USER_EXPLICIT":
                utxt = clean_user_content(content)
                if utxt:
                    if not first_prompt:
                        first_prompt = utxt[:120]
                    messages.append({"role": "user", "ts": ts, "text": utxt})
                    md_lines.extend([f"## 👤 User (`{ts}`)", "", utxt, ""])
            elif stype == "PLANNER_RESPONSE":
                if content and content.strip():
                    messages.append({
                        "role": "assistant",
                        "ts": ts,
                        "text": content.strip(),
                        "thinking": thinking.strip() if thinking else "",
                        "tools": [tc.get("name", "tool") for tc in (tool_calls or [])],
                    })
                    md_lines.extend([f"## 🤖 Assistant (`{ts}`)", "", content.strip(), ""])

        md_text = "\n".join(md_lines)
        (out_conv_dir / "conversation.md").write_text(md_text)

        items.append({
            "agent": "Google Antigravity (agy)",
            "agent_id": "antigravity",
            "session_id": conv_id,
            "title": first_prompt or f"Session {conv_id}",
            "created_at": created_at,
            "step_count": len(steps),
            "messages": messages,
            "rel_path": f"antigravity/{conv_id}/conversation.md",
        })
    return items


def parse_generic_jsonl_tree(home: pathlib.Path, agent_cfg: dict, dest_root: pathlib.Path) -> list[dict]:
    items = []
    found_files = []
    for rel in agent_cfg["paths"]:
        p = home / rel
        if not p.exists():
            continue
        if p.is_file():
            found_files.append((p, p.name))
        elif p.is_dir():
            for sub in sorted(p.rglob("*")):
                if sub.is_file() and sub.suffix in {".jsonl", ".json", ".md"}:
                    found_files.append((sub, str(sub.relative_to(p))))

    if not found_files:
        return items

    dest_root.mkdir(parents=True, exist_ok=True)
    for src_file, rel_name in found_files:
        target_path = dest_root / rel_name
        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src_file, target_path)

        messages = []
        raw_text = src_file.read_text(errors="replace")
        if src_file.suffix == ".jsonl":
            lines = [l for l in raw_text.splitlines() if l.strip()]
            for line in lines[:500]:
                try:
                    obj = json.loads(line)
                    role = obj.get("role") or obj.get("type") or obj.get("sender") or "entry"
                    txt = (
                        obj.get("content")
                        or obj.get("message")
                        or obj.get("text")
                        or obj.get("display")
                        or json.dumps(obj)[:600]
                    )
                    if not isinstance(txt, str):
                        txt = json.dumps(txt, indent=2)
                    ts = obj.get("timestamp") or obj.get("created_at") or obj.get("createdAt") or ""
                    messages.append({"role": str(role), "ts": str(ts), "text": txt})
                except Exception:
                    pass
        else:
            messages.append({"role": "file", "ts": "", "text": raw_text[:10000]})

        mtime_iso = datetime.datetime.fromtimestamp(
            src_file.stat().st_mtime, tz=datetime.timezone.utc
        ).strftime("%Y-%m-%dT%H:%M:%SZ")

        items.append({
            "agent": agent_cfg["name"],
            "agent_id": agent_cfg["id"],
            "session_id": rel_name,
            "title": f"{agent_cfg['name']} — {rel_name}",
            "created_at": mtime_iso,
            "step_count": len(messages),
            "messages": messages,
            "rel_path": f"{agent_cfg['id']}/{rel_name}",
        })
    return items


def build_unified_html(sessions: list[dict], generated_at: str) -> str:
    payload = json.dumps({"generatedAt": generated_at, "sessions": sessions}).replace("</", "<\\/")
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>agent-wrangler — Unified Agent Session Backup</title>
<style>
  :root {
    --bg: #0f1117; --panel: #161922; --border: #2a2f42;
    --text: #e6e8f0; --muted: #949ab1; --accent: #7c9cff;
    --code-bg: #0b0d12;
  }
  [data-theme="light"] {
    --bg: #f6f8fa; --panel: #ffffff; --border: #d8dee4;
    --text: #1f2328; --muted: #59636e; --accent: #2563eb;
    --code-bg: #f3f4f6;
  }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); color: var(--text); display: flex; height: 100vh; overflow: hidden; }
  .sidebar { width: 340px; background: var(--panel); border-right: 1px solid var(--border); display: flex; flex-direction: column; }
  .sidebar-hdr { padding: 16px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; font-weight: 700; }
  .sidebar-list { flex: 1; overflow-y: auto; padding: 10px; }
  .item { padding: 12px; border-radius: 8px; cursor: pointer; margin-bottom: 6px; border: 1px solid transparent; }
  .item:hover { background: rgba(124,156,255,0.06); }
  .item.active { border-color: var(--accent); background: rgba(124,156,255,0.12); }
  .item-title { font-size: 13px; font-weight: 600; margin-bottom: 4px; word-break: break-word; }
  .item-meta { font-size: 11px; color: var(--muted); }
  .main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
  .main-hdr { padding: 16px 24px; background: var(--panel); border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
  .content { flex: 1; overflow-y: auto; padding: 24px; max-width: 1000px; }
  .msg { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 14px 18px; margin-bottom: 12px; }
  .msg-hdr { font-size: 12px; color: var(--muted); font-weight: 600; margin-bottom: 6px; display: flex; justify-content: space-between; }
  .pre { white-space: pre-wrap; word-break: break-word; font-size: 13.5px; line-height: 1.5; }
  .btn { background: transparent; border: 1px solid var(--border); color: var(--text); padding: 5px 10px; border-radius: 6px; cursor: pointer; font-size: 12px; }
</style>
</head>
<body>
  <div class="sidebar">
    <div class="sidebar-hdr">
      <span>🗂️ Agent Session Archive</span>
      <button class="btn" onclick="toggleTheme()">Theme</button>
    </div>
    <div class="sidebar-list" id="list"></div>
  </div>
  <div class="main">
    <div class="main-hdr" id="hdr"></div>
    <div class="content" id="content"></div>
  </div>
<script id="data" type="application/json">__PAYLOAD__</script>
<script>
const DATA = JSON.parse(document.getElementById('data').textContent);
let cur = 0;
function toggleTheme() {
  const h = document.documentElement;
  h.setAttribute('data-theme', h.getAttribute('data-theme') === 'light' ? 'dark' : 'light');
}
function esc(s) {
  return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
function select(i) { cur = i; render(); }
function render() {
  const list = document.getElementById('list');
  if (!DATA.sessions.length) {
    list.innerHTML = '<div style="padding:12px;color:var(--muted)">No sessions found.</div>';
    document.getElementById('content').innerHTML = '<div class="msg">No agent sessions found in home directory.</div>';
    return;
  }
  list.innerHTML = DATA.sessions.map((s, i) => `
    <div class="item ${i === cur ? 'active' : ''}" onclick="select(${i})">
      <div class="item-title">${esc(s.title)}</div>
      <div class="item-meta">${esc(s.agent)} • ${s.step_count} entries • ${esc(s.created_at)}</div>
    </div>`).join('');
  const s = DATA.sessions[cur];
  document.getElementById('hdr').innerHTML = `
    <div>
      <div style="font-weight:700;font-size:16px">${esc(s.title)}</div>
      <div style="font-size:12px;color:var(--muted)">${esc(s.agent)} • File: <code>${esc(s.rel_path)}</code></div>
    </div>`;
  document.getElementById('content').innerHTML = (s.messages || []).map(m => `
    <div class="msg">
      <div class="msg-hdr"><span>${esc(m.role)}</span><span>${esc(m.ts)}</span></div>
      <div class="pre">${esc(m.text)}</div>
    </div>`).join('');
}
render();
</script>
</body>
</html>""".replace("__PAYLOAD__", payload)


def main():
    parser = argparse.ArgumentParser(description="Back up coding agent sessions into a portable archive.")
    parser.add_argument("--home", default=os.environ.get("HOME", "/home/agent"), help="Agent home directory to scan")
    parser.add_argument("--out", default="/work/agent-session-backups", help="Output backup directory")
    args = parser.parse_args()

    home_dir = pathlib.Path(args.home).expanduser()
    out_dir = pathlib.Path(args.out).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)

    all_sessions = []
    for cfg in AGENT_SOURCES:
        if cfg["kind"] == "antigravity_brain":
            brain_path = home_dir / cfg["paths"][0]
            all_sessions.extend(parse_antigravity_brain(brain_path, out_dir / cfg["id"]))
        else:
            all_sessions.extend(parse_generic_jsonl_tree(home_dir, cfg, out_dir / cfg["id"]))

    now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    (out_dir / "index.html").write_text(build_unified_html(all_sessions, now_iso))

    summary_lines = [
        "# Agent Session Backup Summary",
        "",
        f"- **Generated At**: `{now_iso}`",
        f"- **Source Home Directory**: `{home_dir}`",
        f"- **Total Sessions Archived**: `{len(all_sessions)}`",
        "",
        "## Sessions Inventory",
        "",
        "| Agent | Session ID / Path | Entries | Created / Modified | Backup File |",
        "| :--- | :--- | :---: | :--- | :--- |",
    ]
    for s in all_sessions:
        summary_lines.append(
            f"| {s['agent']} | `{s['session_id']}` | {s['step_count']} | `{s['created_at']}` | `{s['rel_path']}` |"
        )
    (out_dir / "SUMMARY.md").write_text("\n".join(summary_lines) + "\n")

    print(json.dumps({
        "status": "ok",
        "home": str(home_dir),
        "output_dir": str(out_dir),
        "total_sessions": len(all_sessions),
        "viewer_html": str(out_dir / "index.html"),
        "summary_md": str(out_dir / "SUMMARY.md"),
    }, indent=2))


if __name__ == "__main__":
    main()
