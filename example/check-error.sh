#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
godot --headless --editor --quit --check-only --debug --path godot
