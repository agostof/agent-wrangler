#!/usr/bin/env python3
"""
Sync Ollama (or any OpenAI-compatible) models into pi's models.json.

Usage:
    python sync-ollama-models.py                                     # uses defaults
    python sync-ollama-models.py --host ollama3 --provider dev-ollama
    python sync-ollama-models.py --pi-config-dir /custom/path/to/pi
    python sync-ollama-models.py --help

Environment variables (overrides CLI defaults where applicable):
    OLLAMA_HOST              Hostname (default: ollama)
    OLLAMA_PORT              Port (default: 11434)
    OLLAMA_PROVIDER_NAME     Provider name in models.json (default: ollama)

The hostname defaults to 'ollama' to support containerized setups where
the Ollama container is on the local Docker network.
"""

import argparse
import json
import os
import shutil
import sys
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path
from typing import Any

# ── Defaults (overridden by env vars, then by CLI flags) ──────────────────

DEFAULT_HOST = os.environ.get("OLLAMA_HOST", "ollama")
DEFAULT_PORT = os.environ.get("OLLAMA_PORT", "11434")
DEFAULT_PROVIDER = os.environ.get("OLLAMA_PROVIDER_NAME", "ollama")


def load_config(path: Path) -> dict[str, Any]:
    """Load the pi models.json config."""
    try:
        with open(path, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"providers": {}}
    except json.JSONDecodeError as e:
        print(f"Error parsing {path}: {e}", file=sys.stderr)
        sys.exit(1)


def build_url(host: str, port: str) -> str:
    """Build the baseUrl for the provider."""
    return f"http://{host}:{port}/v1"


def get_provider_url(config: dict, provider_name: str) -> str:
    """Extract the baseUrl for a provider and append /models."""
    providers = config.get("providers", {})
    provider = providers.get(provider_name, {})
    base = provider.get("baseUrl", "")
    if base:
        return base.rstrip("/") + "/models"
    # Fallback: build from host/port
    return build_url(DEFAULT_HOST, DEFAULT_PORT) + "/models"


def fetch_remote_models(url: str) -> list[str]:
    """Fetch model IDs from an OpenAI-compatible /models endpoint."""
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
    except urllib.error.URLError as e:
        print(f"\nError fetching models from {url}: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"\nError parsing response from {url}: {e}", file=sys.stderr)
        sys.exit(1)

    models_data = data.get("data", [])
    ids = [m["id"] for m in models_data if isinstance(m, dict) and "id" in m]
    ids.sort()
    return ids


def get_current_model_ids(config: dict, provider_name: str) -> list[str]:
    """Extract currently configured model IDs for a provider."""
    models = config.get("providers", {}).get(provider_name, {}).get("models", [])
    return [m["id"] for m in models if isinstance(m, dict) and "id" in m]


def interactive_select(available: list[str], enabled: set[str]) -> set[str]:
    """
    Display a numbered list of models with checkmarks for enabled ones.
    User types comma-separated numbers or names to toggle selection.
    Type 'done' or just press Enter to finish.
    """
    print("\nAvailable models ( [*] = currently enabled in pi config ):")
    print("-" * 60)
    for i, mid in enumerate(available, 1):
        marker = "[*] " if mid in enabled else "[ ] "
        print(f"  {marker}{i:3d}. {mid}")
    print("-" * 60)
    print("\n  Toggle models by number (e.g. '1,3,5') or ID name.")
    print("  Type 'done' (or just press Enter) to finish.")
    print("  Type 'all' to select everything, 'none' to deselect everything.\n")

    selected = set(enabled)

    while True:
        prompt = "> "
        raw = input(prompt).strip()

        if not raw or raw.lower() == "done":
            break

        if raw.lower() == "all":
            selected = set(available)
            print("  -> Selected all models.")
            continue

        if raw.lower() == "none":
            selected = set()
            print("  -> Deselected all models.")
            continue

        # Try to parse as comma-separated numbers or IDs
        parts = [p.strip() for p in raw.split(",")]
        toggled = False
        for part in parts:
            # Try number index
            if part.isdigit():
                idx = int(part) - 1
                if 0 <= idx < len(available):
                    mid = available[idx]
                    if mid in selected:
                        selected.discard(mid)
                        print(f"  -> Deselected: {mid}")
                    else:
                        selected.add(mid)
                        print(f"  -> Selected:    {mid}")
                    toggled = True
                    continue
            # Try direct ID
            if part in available:
                if part in selected:
                    selected.discard(part)
                    print(f"  -> Deselected: {part}")
                else:
                    selected.add(part)
                    print(f"  -> Selected:    {part}")
                toggled = True
                continue

            print(f"  -> Unknown: '{part}' (use a number {1}-{len(available)} or an exact model ID)")

        if not toggled:
            print("  (no valid selections found)")

    return selected


def show_selection_summary(available: list[str], enabled: set[str], selected: set[str]) -> None:
    """Print a side-by-side summary so the user can verify before writing."""
    selected_sorted = sorted(selected)
    enabled_sorted = sorted(enabled)
    added = sorted(selected - enabled)
    removed = sorted(enabled - selected)
    unchanged = selected & enabled

    print(f"\n{'=' * 60}")
    print("Selection preview:")
    print(f"{'=' * 60}")

    if not selected_sorted:
        print("  No models selected.")
    else:
        print(f"  {len(selected_sorted)} model(s) will be enabled:")
        for mid in selected_sorted:
            status = "new" if mid in added else "unchanged"
            print(f"    [*] {mid}          ({status})")

    if removed:
        print(f"\n  {len(removed)} model(s) will be removed:")
        for mid in removed:
            print(f"    [x] {mid}")

    # Count summary
    total_new = len(added)
    total_drop = len(removed)
    total_keep = len(unchanged)
    print(f"\n  Summary: {total_new} added, {total_drop} removed, {total_keep} unchanged")
    print(f"{'=' * 60}")


def selections_changed(enabled: set[str], selected: set[str]) -> bool:
    """Check if the selection differs from what's currently enabled."""
    return enabled != selected


def build_provider_config(provider_name: str, config: dict, host: str,
                          port: str, model_ids: set[str]) -> dict:
    """
    Build the provider config section, preserving existing settings
    (apiKey, api, compat, headers) and updating baseUrl + models list.
    """
    existing = config.get("providers", {}).get(provider_name, {})

    api = existing.get("apiKey", "ollama")
    api_type = existing.get("api", "openai-completions")
    compat = existing.get("compat", {})
    headers = existing.get("headers", None)
    auth_header = existing.get("authHeader", None)

    # Build fresh baseUrl from host/port
    base_url = build_url(host, port)

    models_list = [{"id": mid} for mid in sorted(model_ids)]

    provider = {
        "baseUrl": base_url,
        "apiKey": api,
        "api": api_type,
        "models": models_list,
    }

    if compat:
        provider["compat"] = compat
    if headers:
        provider["headers"] = headers
    if auth_header is not None:
        provider["authHeader"] = auth_header

    return provider


def backup_config(path: Path) -> Path:
    """Create a timestamped backup of the config file."""
    if not path.exists():
        return path
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_suffix(f".json.backup.{ts}")
    shutil.copy2(path, backup)
    return backup


def write_config(path: Path, config: dict) -> None:
    """Write the updated config back to file."""
    with open(path, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")


def resolve_pi_models_path(pi_config_dir: str | None) -> Path:
    """Resolve the full path to models.json."""
    if pi_config_dir:
        return Path(pi_config_dir) / "models.json"
    return Path.home() / ".pi" / "agent" / "models.json"


def main():
    parser = argparse.ArgumentParser(
        description="Sync Ollama models into pi's models.json",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Environment variables:\n"
            "  OLLAMA_HOST           Hostname (default: ollama)\n"
            "  OLLAMA_PORT           Port     (default: 11434)\n"
            "  OLLAMA_PROVIDER_NAME  Provider name (default: ollama)\n"
        ),
    )
    parser.add_argument(
        "--host",
        default=DEFAULT_HOST,
        help=f"Ollama hostname (default: {DEFAULT_HOST})",
    )
    parser.add_argument(
        "--port",
        default=DEFAULT_PORT,
        help=f"Ollama port (default: {DEFAULT_PORT})",
    )
    parser.add_argument(
        "--provider",
        default=DEFAULT_PROVIDER,
        help=f"Provider name in models.json (default: {DEFAULT_PROVIDER})",
    )
    parser.add_argument(
        "--pi-config-dir",
        default=None,
        help="Path to pi config directory containing models.json",
    )
    args = parser.parse_args()

    provider_name = args.provider
    host = args.host
    port = args.port
    models_path = resolve_pi_models_path(args.pi_config_dir)

    print(f"Provider     : {provider_name}")
    print(f"Host         : {host}")
    print(f"Port         : {port}")
    print(f"Config file  : {models_path}")

    # Load existing config
    config = load_config(models_path)

    # Get the baseUrl for this provider and fetch remote models
    models_url = get_provider_url(config, provider_name)
    print(f"Fetching     : {models_url}")

    print("\nFetching available models...")
    remote_ids = fetch_remote_models(models_url)
    if not remote_ids:
        print("No models found at the remote endpoint.", file=sys.stderr)
        sys.exit(0)
    print(f"Found {len(remote_ids)} model(s).")

    # Get currently enabled model IDs
    current_ids = get_current_model_ids(config, provider_name)
    enabled_set = set(current_ids)

    # Interactive selection
    selected = interactive_select(remote_ids, enabled_set)

    # Show summary
    show_selection_summary(remote_ids, enabled_set, selected)

    # Only write if selections actually changed
    if not selections_changed(enabled_set, selected):
        print("\nNo changes detected. Skipping write.")
        return

    # Safety check: deselecting everything
    if not selected and enabled_set:
        confirm = input("\nAll models would be removed. Continue? [y/N] ").strip().lower()
        if confirm not in ("y", "yes"):
            print("Aborted.")
            sys.exit(0)

    # Confirm before writing
    confirm = input("\nWrite updated config? [Y/n] ").strip().lower()
    if confirm in ("n", "no"):
        print("Aborted.")
        sys.exit(0)

    # Backup and write
    backup = backup_config(models_path)
    print(f"\nBacked up config -> {backup}")

    provider_cfg = build_provider_config(provider_name, config, host, port, selected)
    config.setdefault("providers", {})[provider_name] = provider_cfg

    write_config(models_path, config)
    print(f"Wrote updated {models_path}")
    print("\nOpen pi and run /model to see the changes take effect.")


if __name__ == "__main__":
    main()
