#!/usr/bin/env python3
"""Run the Godobuf performance benchmark.

Usage:
    python3 run-bench.py              # run benchmark, print results
    python3 run-bench.py --json       # output JSON for automated analysis

Requires:
    - Godot 4.x on PATH (or set GODOT_BIN)
    - Generated .gd files (run build-proto.py first if needed)
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GODOT_DIR = ROOT / "godot"
BENCH_SCRIPT = "benchmark.gd"


def find_godot() -> str:
    env_val = os.environ.get("GODOT_BIN")
    if env_val:
        return env_val
    import shutil
    found = shutil.which("godot")
    if found:
        return found
    print("error: godot not found. Set GODOT_BIN or add godot to PATH.",
          file=sys.stderr)
    sys.exit(1)


def parse_bench_output(text: str) -> list[dict]:
    """Parse benchmark output into structured records."""
    results: list[dict] = []
    # Match lines like: "  Player.new()                     total=  123.45 ms  per_op=  12.35 us"
    pattern = re.compile(
        r"^\s{2}(?P<label>.+?)\s{2,}"
        r"total=\s*(?P<total_ms>[\d.]+)\s*ms\s+"
        r"per_op=\s*(?P<per_op_us>[\d.]+)\s*us"
    )
    for line in text.splitlines():
        m = pattern.match(line)
        if m:
            results.append({
                "label": m.group("label").strip(),
                "total_ms": float(m.group("total_ms")),
                "per_op_us": float(m.group("per_op_us")),
            })

    # Match scale-test lines: "  size=  50  total_adds=  500  per_add=    9.20 us"
    scale_pattern = re.compile(
        r"^\s{2}size=\s*(?P<size>\d+)\s+"
        r"total_adds=\s*(?P<total>\d+)\s+"
        r"per_add=\s*(?P<per_add_us>[\d.]+)\s*us"
    )
    for line in text.splitlines():
        m = scale_pattern.match(line)
        if m:
            results.append({
                "label": f"find_map_index(size={m.group('size')})",
                "size": int(m.group("size")),
                "total_adds": int(m.group("total")),
                "per_op_us": float(m.group("per_add_us")),
                "category": "scale",
            })

    # Match BM7 comparison: "  proto_map size=  10  per_add=    9.39 us"
    bm7_pattern = re.compile(
        r"^\s{2}(?P<kind>proto_map|native_dict)\s+size=\s*(?P<size>\d+)\s+"
        r"per_add=\s*(?P<per_add_us>[\d.]+)\s*us"
    )
    for line in text.splitlines():
        m = bm7_pattern.match(line)
        if m:
            results.append({
                "label": f"{m.group('kind')}(size={m.group('size')})",
                "size": int(m.group("size")),
                "per_op_us": float(m.group("per_add_us")),
                "kind": m.group("kind"),
                "category": "scale",
            })
    return results


def print_table(results: list[dict]) -> None:
    """Print results as a formatted table."""
    print()
    print(f"{'Benchmark':<45} {'Total (ms)':>10} {'µs/op':>10}")
    print("-" * 67)
    for r in results:
        if r.get("category") == "scale":
            continue
        print(f"{r['label']:<45} {r['total_ms']:>10.2f} {r['per_op_us']:>10.2f}")

    # Scale results
    scale = [r for r in results if r.get("category") == "scale"]
    if scale:
        print()
        print("── Scale Tests ──")
        for r in scale:
            print(f"  {r['label']:<50} {r['per_op_us']:>10.2f} µs/op")


def main() -> None:
    godot = find_godot()
    json_out = "--json" in sys.argv

    # Ensure generated .gd files exist
    player_gd = GODOT_DIR / "resources" / "proto" / "player.gd"
    if not player_gd.exists():
        print("Generated .gd files not found. Run build-proto.py first:")
        print(f"  python3 {ROOT / 'build-proto.py'}")
        sys.exit(1)

    bench_path = GODOT_DIR / BENCH_SCRIPT
    if not bench_path.exists():
        print(f"Benchmark script not found: {bench_path}")
        sys.exit(1)

    print(f"  godot:  {godot}")
    print(f"  script: {bench_path}")
    print(f"  project: {GODOT_DIR}")
    print()

    cmd = [
        godot, "--headless", "--quit",
        "--path", str(GODOT_DIR),
        "-s", str(bench_path),
    ]

    result = subprocess.run(
        cmd,
        capture_output=True, text=True,
        cwd=ROOT,
        timeout=120,
    )

    output = result.stdout + result.stderr

    if result.returncode != 0:
        print(output)
        print(f"\nBenchmark failed with exit code {result.returncode}",
              file=sys.stderr)
        sys.exit(result.returncode)

    if json_out:
        parsed = parse_bench_output(output)
        json.dump(parsed, sys.stdout, indent=2)
        print()
    else:
        print(output)
        parsed = parse_bench_output(output)
        if parsed:
            print_table(parsed)


if __name__ == "__main__":
    main()
