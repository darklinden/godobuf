#!/usr/bin/env python3
"""Build protobuf codegen for Godot — runs the godobuf protoc plugin.

Usage:
    python3 build-proto.py               # compile all .proto files
    python3 build-proto.py player.proto  # compile a single file

Requires:
    - protoc on PATH (or set PROTOC_BIN)
    - uv (for running the plugin from source)
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROTO_DIR = ROOT / "proto"
GODOT_PROTO_OUT = ROOT / "godot" / "resources" / "proto"
PLUGIN_DIR = ROOT.parent


def find_protoc() -> str:
    env_val = os.environ.get("PROTOC_BIN")
    if env_val:
        return env_val
    found = shutil.which("protoc")
    if found:
        return found
    print("error: protoc not found. Set PROTOC_BIN or add protoc to PATH.", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    protoc = find_protoc()
    print(f"  protoc: {protoc}")

    # Install plugin in editable mode (fast, caches well)
    subprocess.run(
        ["uv", "pip", "install", "-e", str(PLUGIN_DIR)],
        cwd=PLUGIN_DIR,
        check=True,
    )

    # Resolve plugin path
    result = subprocess.run(
        ["uv", "run", "which", "protoc-gen-gd"],
        cwd=PLUGIN_DIR,
        capture_output=True, text=True, check=True,
    )
    plugin_bin = result.stdout.strip()
    print(f"  plugin: {plugin_bin}")

    GODOT_PROTO_OUT.mkdir(parents=True, exist_ok=True)

    # Pick proto files from args or default to all
    args = sys.argv[1:]
    if args:
        proto_files = [PROTO_DIR / a for a in args]
    else:
        proto_files = sorted(PROTO_DIR.glob("*.proto"))
    proto_paths = [str(p) for p in proto_files]

    print(f"  proto:  {[p.name for p in proto_files]}")
    print(f"  out:    {GODOT_PROTO_OUT}")

    cmd = [
        protoc,
        "-I", str(PROTO_DIR),
        f"--plugin=protoc-gen-gd={plugin_bin}",
        f"--gd_out={GODOT_PROTO_OUT}",
    ] + proto_paths

    result = subprocess.run(cmd, cwd=PLUGIN_DIR)
    if result.returncode != 0:
        print("protoc failed", file=sys.stderr)
        sys.exit(result.returncode)

    print("  -> godot/resources/proto/")
    print("=== Proto build complete ===")


if __name__ == "__main__":
    main()
