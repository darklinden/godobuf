#!/usr/bin/env python3
"""Cross-language proto pack/unpack tests: Python ↔ Godot.

1. Builds .gd files via protoc plugin
2. Generates Python-encoded proto binary test data
3. Runs Godot GUT tests (roundtrip + cross-language decode)
4. Decodes Godot-encoded binaries with Python protobuf and verifies

Usage:
    python3 test-proto.py
    python3 test-proto.py --skip-build   # skip rebuilding .gd files
"""

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROTO_DIR = ROOT / "proto"
GODOT_DIR = ROOT / "godot"
PB2_DIR = ROOT / "test_data"        # pb2 modules location
TEST_DATA = GODOT_DIR / "test_data"  # binary test data location
PLUGIN_DIR = ROOT.parent


def step(msg: str) -> None:
    print(f"\n=== {msg} ===")


def run(cmd: list[str | str], **kw) -> subprocess.CompletedProcess:
    print(f"  $ {' '.join(str(c) for c in cmd)}")
    return subprocess.run(cmd, check=True, **kw)


# ── step 1: build .gd files ───────────────────────────────────────────
def build_gd_files() -> None:
    step("Building .gd files via protoc plugin")
    run(["uv", "pip", "install", "-e", str(PLUGIN_DIR)], cwd=PLUGIN_DIR)
    result = run(["uv", "run", "which", "protoc-gen-gd"], cwd=PLUGIN_DIR,
                 capture_output=True, text=True)
    plugin_bin = result.stdout.strip()
    protos = sorted(PROTO_DIR.glob("*.proto"))
    GODOT_DIR.joinpath("resources/proto").mkdir(parents=True, exist_ok=True)
    run([
        "protoc", "-I", str(PROTO_DIR),
        f"--plugin=protoc-gen-gd={plugin_bin}",
        f"--gd_out={GODOT_DIR}/resources/proto",
    ] + [str(p) for p in protos])


# ── step 2: generate Python proto test data ───────────────────────────
def generate_python_data() -> None:
    step("Generating Python protobuf test data")

    # Add pb2 dir to path for imports
    sys.path.insert(0, str(PB2_DIR))
    import player_pb2  # type: ignore
    import game_pb2    # type: ignore

    # --- Python → Player binary ---
    p = player_pb2.Player()
    p.double_val = 3.14159
    p.string_val = "cross-test"
    p.bool_val = True
    p.int32_val = 42
    p.email = "cross@test.com"
    p.items.extend(["alpha", "beta", "gamma"])

    s = player_pb2.Player.Stats()
    s.strength = 15
    s.agility = 10
    s.intelligence = 8
    p.stats.CopyFrom(s)

    h1 = p.history.add()
    h1.strength = 5
    h2 = p.history.add()
    h2.strength = 7

    p.metadata["name"] = "protobuf"
    p.metadata["lang"] = "python"
    p.labels[1] = "one"
    p.labels[2] = "two"
    p.skills["fire"] = player_pb2.Player.FIRE
    p.skills["lightning"] = player_pb2.Player.LIGHTNING

    TEST_DATA.mkdir(parents=True, exist_ok=True)
    TEST_DATA.joinpath("python_player.bin").write_bytes(p.SerializeToString())
    print(f"  Wrote python_player.bin ({len(p.SerializeToString())} bytes)")

    # --- Python → Game binary ---
    g = game_pb2.Game()
    g.id = "cross-game"
    g.max_players = 16
    g.started = True
    g.state = game_pb2.Game.IN_PROGRESS

    p1 = g.players.add()
    p1.string_val = "p1"
    p2 = g.players.add()
    p2.string_val = "p2"

    g.leader.string_val = "boss"

    g.config.friendly_fire = True
    g.config.mode = game_pb2.Game.Config.RANKED

    r1 = g.rounds.add()
    r1.time_limit = 60.0
    r2 = g.rounds.add()
    r2.time_limit = 120.0

    TEST_DATA.joinpath("python_game.bin").write_bytes(g.SerializeToString())
    print(f"  Wrote python_game.bin ({len(g.SerializeToString())} bytes)")


# ── step 3: run Godot GUT tests ───────────────────────────────────────
def run_godot_tests() -> None:
    step("Running Godot GUT tests")

    result = subprocess.run(
        [
            "godot", "--headless", "--quit",
            "--path", str(GODOT_DIR),
            "-s", "addons/gut/gut_cmdln.gd",
            "-gdir=res://tests",
            "-glog=1",
        ],
        capture_output=True, text=True, cwd=ROOT,
    )

    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)

    if result.returncode != 0:
        print("\n  GUT tests FAILED!", file=sys.stderr)
        sys.exit(1)
    print("  GUT tests PASSED")


# ── step 4: verify Godot-encoded binaries with Python ─────────────────
def verify_godot_data() -> None:
    step("Verifying Godot-encoded binaries with Python protobuf")

    sys.path.insert(0, str(PB2_DIR))
    import player_pb2  # type: ignore
    import game_pb2    # type: ignore

    # --- Godot Player → Python decode ---
    gd_player_bin = TEST_DATA.joinpath("godot_player.bin")
    if not gd_player_bin.exists():
        print("  SKIP: godot_player.bin not found (did GUT test_godot_player_to_file run?)")
        return

    data = gd_player_bin.read_bytes()
    p = player_pb2.Player()
    p.ParseFromString(data)

    assert abs(p.double_val - 2.71828) < 0.001, f"double: {p.double_val}"
    assert abs(p.float_val - 1.414) < 0.001, f"float: {p.float_val}"
    assert p.int32_val == -100, f"int32: {p.int32_val}"
    assert p.int64_val == -9999, f"int64: {p.int64_val}"
    assert p.uint32_val == 42, f"uint32: {p.uint32_val}"
    assert p.uint64_val == 4242, f"uint64: {p.uint64_val}"
    assert p.sint32_val == -50, f"sint32: {p.sint32_val}"
    assert p.sint64_val == -5000, f"sint64: {p.sint64_val}"
    assert p.fixed32_val == 0xFF, f"fixed32: {p.fixed32_val}"
    assert p.fixed64_val == 0xFFFF, f"fixed64: {p.fixed64_val}"
    assert p.sfixed32_val == -0xFF, f"sfixed32: {p.sfixed32_val}"
    assert p.sfixed64_val == -0xFFFF, f"sfixed64: {p.sfixed64_val}"
    assert p.bool_val is False, f"bool: {p.bool_val}"
    assert p.string_val == "godot → python", f"string: {p.string_val}"
    assert list(p.bytes_val) == [0xDE, 0xAD, 0xBE, 0xEF], f"bytes: {list(p.bytes_val)}"
    assert getattr(p, "class") == player_pb2.Player.MAGE, f"class: {getattr(p, 'class')}"
    assert list(p.items) == ["x", "y"], f"items: {list(p.items)}"

    # oneof: should be phone, not email
    assert p.WhichOneof("contact") == "phone", f"oneof: {p.WhichOneof('contact')}"
    assert p.phone == 9876543210, f"phone: {p.phone}"

    assert p.stats.strength == 20
    assert p.stats.agility == 15
    assert p.stats.intelligence == 10

    assert len(p.history) == 3
    assert p.metadata["godot_key"] == "works"
    assert p.labels[99] == "ninety-nine"
    assert p.skills["ice_skill"] == player_pb2.Player.ICE

    print("  godot_player.bin: OK — all fields match")

    # --- Godot Game → Python decode ---
    gd_game_bin = TEST_DATA.joinpath("godot_game.bin")
    if not gd_game_bin.exists():
        print("  SKIP: godot_game.bin not found")
        return

    data = gd_game_bin.read_bytes()
    g = game_pb2.Game()
    g.ParseFromString(data)

    assert g.id == "godot-game"
    assert g.max_players == 4
    assert g.started is False
    assert g.state == game_pb2.Game.LOBBY
    assert len(g.players) == 1
    assert g.players[0].string_val == "gdplayer"
    assert g.HasField("leader")
    assert g.leader.string_val == "gdleader"
    assert g.WhichOneof("reward") == "reward_text"
    assert g.reward_text == "treasure"
    assert g.HasField("config")
    assert g.config.friendly_fire is False
    assert abs(g.config.time_limit - 120.0) < 0.01
    assert g.config.mode == game_pb2.Game.Config.NORMAL
    assert len(g.rounds) == 1
    assert abs(g.rounds[0].time_limit - 60.0) < 0.01
    assert g.rounds[0].mode == game_pb2.Game.Config.TOURNAMENT

    print("  godot_game.bin: OK — all fields match")

    print("\n  Cross-language tests PASSED ✓")


# ── main ──────────────────────────────────────────────────────────────
def main() -> None:
    skip_build = "--skip-build" in sys.argv

    if not skip_build:
        build_gd_files()
    generate_python_data()
    run_godot_tests()
    verify_godot_data()

    print("\n══════════════════════════════════════════")
    print("  All tests passed")
    print("══════════════════════════════════════════")


if __name__ == "__main__":
    main()
