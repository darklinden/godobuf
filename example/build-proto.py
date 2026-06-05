#!/usr/bin/env python3
"""Build protobuf codegen for Godot (godobuf).

Runs godobuf CLI for each .proto file, outputting to the example Godot project.

Requires:
    - Godot 4.x with godobuf addon available
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path


IS_WINDOWS = sys.platform == "win32"

ROOT = Path(__file__).resolve().parent
PROTO_DIR = ROOT / "proto"
GODOT_PROJECT = ROOT / "godot"
GODOT_PROTO_OUT = GODOT_PROJECT / "resources" / "proto"

_DEFAULT_GODOT_PATHS: dict[str, list[str]] = {
    "darwin": [
        "/Applications/Godot.app/Contents/MacOS/Godot",
        "/Applications/Godot_mono.app/Contents/MacOS/Godot",
    ],
    "win32": [
        "C:/Program Files/Godot/Godot.exe",
        "C:/Program Files (x86)/Godot/Godot.exe",
    ],
}


def _parse_dotenv(dotenv_path: Path) -> dict[str, str]:
    """Parse a .env file, returning key-value pairs."""
    pairs: dict[str, str] = {}
    if not dotenv_path.exists():
        return pairs
    for line in dotenv_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if "=" not in stripped:
            continue
        key, _, value = stripped.partition("=")
        pairs[key.strip()] = value.strip().strip("\"'")
    return pairs


def find_godot() -> str:
    """Resolve the Godot binary path.

    Priority order:
      1. GODOT_BIN environment variable
      2. GODOT_BIN in .env file at example root
      3. ``godot`` / ``Godot.exe`` on PATH
      4. Platform default install paths
    """
    env_val = os.environ.get("GODOT_BIN")
    if env_val:
        print(f"  [info] using GODOT_BIN from env: {env_val}")
        return env_val

    dotenv = _parse_dotenv(ROOT / ".env")
    dotenv_val = dotenv.get("GODOT_BIN", "")
    if dotenv_val:
        print(f"  [info] using GODOT_BIN from .env: {dotenv_val}")
        return dotenv_val

    path_val = shutil.which("godot") or (IS_WINDOWS and shutil.which("Godot.exe"))
    if path_val:
        print(f"  [info] using godot from PATH: {path_val}")
        return path_val

    defaults = _DEFAULT_GODOT_PATHS.get(sys.platform, [])
    for candidate in defaults:
        if Path(candidate).exists():
            print(f"  [info] using godot at default path: {candidate}")
            return candidate

    print("error: Godot binary not found.", file=sys.stderr)
    print("  Set GODOT_BIN in environment, .env file, or ensure godot is on PATH.", file=sys.stderr)
    print(f"  Checked default paths: {defaults}", file=sys.stderr)
    sys.exit(1)


GODOT_BIN = find_godot()


def _proto_files() -> list[Path]:
    """Return sorted .proto files."""
    return sorted(PROTO_DIR.glob("*.proto"))


def build_godot() -> None:
    print("=== Building Godot protobuf codegen ===")
    GODOT_PROTO_OUT.mkdir(parents=True, exist_ok=True)

    proto_files = _proto_files()
    if not proto_files:
        print("  No .proto files found, skipping", file=sys.stderr)
        return

    for proto_file in proto_files:
        print(f"  {proto_file.name} -> {proto_file.stem}.gd")
        result = subprocess.run(
            [
                GODOT_BIN,
                "--headless",
                "--quit",
                "--path", str(GODOT_PROJECT),
                "-s", "addons/godobuf/godobuf_cmdln.gd",
                f"--input={proto_file}",
                f"--output=res://resources/proto/{proto_file.stem}.gd",
            ],
            check=False,
        )
        if result.returncode != 0:
            print(f"  godobuf failed for {proto_file.name}", file=sys.stderr)
            sys.exit(1)

    print("  -> godot/resources/proto/")


def main() -> None:
    build_godot()
    print("=== Proto build complete ===")


if __name__ == "__main__":
    main()
