extends SceneTree

## Godobuf Performance Benchmark
##
## Measures the runtime overhead of key operations in generated protobuf code.
## Run with: godot --headless --script benchmark.gd
##
## Each benchmark warms up then measures N iterations, reporting:
##   - total time (ms)
##   - per-iteration time (us)

# ---------------------------------------------------------------------------
# The generated proto files suppress warnings; we need the same treatment
# since we access dynamically-typed inner classes.
# ---------------------------------------------------------------------------
@warning_ignore_start("unsafe_cast", "unsafe_call_argument", "unsafe_method_access", "unsafe_property_access", "untyped_declaration", "inferred_declaration", "return_value_discarded", "static_called_on_instance", "shadowed_variable", "shadowed_variable_base_class", "int_as_enum_without_cast", "int_as_enum_without_match", "integer_division")

const ITERATIONS: int = 10000
const MAP_SCALE_ITERATIONS: int = 1000
const SERIALIZE_ITERATIONS: int = 1000

var _player_script
var _game_script


func _init() -> void:
	_setup()
	_benchmark_all()
	_finish()


func _setup() -> void:
	print("══════════════════════════════════════════════")
	print("  Godobuf Performance Benchmark")
	print("══════════════════════════════════════════════")
	print("  Iterations (message ops): %d" % ITERATIONS)
	print("  Iterations (map ops):     %d" % MAP_SCALE_ITERATIONS)
	print("  Iterations (serialize):   %d" % SERIALIZE_ITERATIONS)
	print("")

	_player_script = load("res://resources/proto/player.gd")
	_game_script = load("res://resources/proto/game.gd")

	# Pre-warm: force script compilation + static init
	var _warm = _player_script.new().Player.new()
	_warm = _game_script.new().Game.new()


func _benchmark_all() -> void:
	bench_message_creation()
	bench_field_set_get()
	bench_repeated_add()
	bench_oneof_set()
	bench_map_construct_get()
	bench_map_find_index_scale()
	bench_map_bulk_add_scale()
	bench_serialize_small()
	bench_serialize_large()
	bench_deserialize_small()
	bench_deserialize_large()
	bench_clear_reset()
	bench_default_values_lookup_vs_inline()
	bench_preload_overhead()


# ── BM 1: Message creation (PBField + PBServiceField allocation) ──

func bench_message_creation() -> void:
	print("── BM 1: Message creation ──")
	print("  Creating Player (24 fields) and Game instances")

	# Player has 24 fields → 24 PBField + 24 PBServiceField + 1 Dictionary
	var start: int = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		var _p = _player_script.new().Player.new()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("Player.new()", elapsed, ITERATIONS)

	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		var _g = _game_script.new().Game.new()
	elapsed = Time.get_ticks_usec() - start
	_report("Game.new()", elapsed, ITERATIONS)

	# Baseline: empty RefCounted
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		var _r: RefCounted = RefCounted.new()
	elapsed = Time.get_ticks_usec() - start
	_report("RefCounted.new() (baseline)", elapsed, ITERATIONS)


# ── BM 2: Field set/get throughput ──

func bench_field_set_get() -> void:
	print("── BM 2: Scalar field set/get ──")

	var p = _player_script.new().Player.new()

	# int32 set
	var start: int = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_int32_val(42)
	var elapsed: int = Time.get_ticks_usec() - start
	_report("set_int32_val()", elapsed, ITERATIONS)

	# int32 get
	p.set_int32_val(42)
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		var _v: int = p.get_int32_val()
	elapsed = Time.get_ticks_usec() - start
	_report("get_int32_val()", elapsed, ITERATIONS)

	# string set
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_string_val("hello world")
	elapsed = Time.get_ticks_usec() - start
	_report("set_string_val()", elapsed, ITERATIONS)

	# string get
	p.set_string_val("hello world")
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		var _v: String = p.get_string_val()
	elapsed = Time.get_ticks_usec() - start
	_report("get_string_val()", elapsed, ITERATIONS)

	# has_ check
	p.set_int32_val(1)
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		var _v: bool = p.has_int32_val()
	elapsed = Time.get_ticks_usec() - start
	_report("has_int32_val()", elapsed, ITERATIONS)

	# Baseline: direct property via set_meta
	var base_obj: RefCounted = RefCounted.new()
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		base_obj.set_meta("v", 42)
	elapsed = Time.get_ticks_usec() - start
	_report("RefCounted.set_meta() (baseline)", elapsed, ITERATIONS)


# ── BM 3: Repeated field add ──

func bench_repeated_add() -> void:
	print("── BM 3: Repeated field add ──")
	var p = _player_script.new().Player.new()

	var start: int = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.add_items("item")
	var elapsed: int = Time.get_ticks_usec() - start
	_report("add_items(String) [repeated]", elapsed, ITERATIONS)

	p.clear_items()

	# Baseline: direct Array.append
	var arr: Array[String] = []
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		arr.append("item")
	elapsed = Time.get_ticks_usec() - start
	_report("Array[String].append() (baseline)", elapsed, ITERATIONS)


# ── BM 4: Oneof set (sibling clear overhead) ──

func bench_oneof_set() -> void:
	print("── BM 4: Oneof set (sibling clear overhead) ──")

	var p = _player_script.new().Player.new()

	# Set without sibling dirty
	var start: int = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_email("a@b.com")
		p.clear_email()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("set_email+clear (no sibling)", elapsed, ITERATIONS)

	# Set with sibling toggle
	p.set_phone(1234567890)
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_email("a@b.com")
		p.set_phone(1234567890)
	elapsed = Time.get_ticks_usec() - start
	_report("set_email<->set_phone toggle", elapsed, ITERATIONS)

	# Baseline: non-oneof set+clear
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_string_val("hello")
		p.clear_string_val()
	elapsed = Time.get_ticks_usec() - start
	_report("set+clear_string (baseline)", elapsed, ITERATIONS)


# ── BM 5: Map get → construct_map allocates new Dictionary ──

func bench_map_construct_get() -> void:
	print("── BM 5: Map get (construct_map allocation) ──")

	var p = _player_script.new().Player.new()
	for i: int in range(50):
		p.add_metadata("key_%d" % i, "value_%d" % i)

	var start: int = Time.get_ticks_usec()
	for _i: int in range(MAP_SCALE_ITERATIONS):
		var _d: Dictionary = p.get_metadata()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("get_metadata() [50 entries]", elapsed, MAP_SCALE_ITERATIONS)

	# Empty map
	p.clear_metadata()
	start = Time.get_ticks_usec()
	for _i: int in range(MAP_SCALE_ITERATIONS * 10):
		var _d: Dictionary = p.get_metadata()
	elapsed = Time.get_ticks_usec() - start
	_report("get_metadata() [0 entries]", elapsed, MAP_SCALE_ITERATIONS * 10)


# ── BM 6: find_map_index O(n) scale ──

func bench_map_find_index_scale() -> void:
	print("── BM 6: find_map_index O(n) scale ──")
	print("  Adding N entries to fresh messages (each add scans for dup)")

	for size: int in [10, 50, 100, 200, 500]:
		var divisor: int = maxi(1, floori(float(size) / 10.0))
		var iters: int = maxi(1, floori(float(MAP_SCALE_ITERATIONS) / float(divisor)))
		var start: int = Time.get_ticks_usec()
		for _j: int in range(iters):
			var px = _player_script.new().Player.new()
			for i: int in range(size):
				px.add_metadata("key_%d" % i, "val_%d" % i)
		var elapsed: int = Time.get_ticks_usec() - start
		var total_adds: int = iters * size
		var per_add: float = float(elapsed) / float(total_adds)
		print("  size=%4d  total_adds=%6d  per_add=%8.2f us" % [size, total_adds, per_add])


# ── BM 7: Map bulk add (O(n²) from linear find_map_index) ──

func bench_map_bulk_add_scale() -> void:
	print("── BM 7: Map bulk add comparison ──")
	print("  vs. plain Dictionary (GDScript native hash map)")

	for size: int in [10, 50, 100, 200]:
		var divisor: int = maxi(1, floori(float(size) / 10.0))
		var iters: int = maxi(1, floori(float(MAP_SCALE_ITERATIONS) / float(divisor)))
		var start: int = Time.get_ticks_usec()
		for _j: int in range(iters):
			var px = _player_script.new().Player.new()
			for i: int in range(size):
				px.add_metadata("key_%d" % i, "value_%d" % i)
		var elapsed: int = Time.get_ticks_usec() - start
		var total: int = iters * size
		var per_add: float = float(elapsed) / float(total)
		print("  proto_map size=%4d  per_add=%8.2f us" % [size, per_add])

		# Native Dictionary baseline
		start = Time.get_ticks_usec()
		for _j: int in range(iters):
			var d: Dictionary = {}
			for i: int in range(size):
				d["key_%d" % i] = "value_%d" % i
		elapsed = Time.get_ticks_usec() - start
		per_add = float(elapsed) / float(total)
		print("  native_dict size=%4d per_add=%8.2f us" % [size, per_add])


# ── BM 8: Serialize small ──

func bench_serialize_small() -> void:
	print("── BM 8: Serialize small message ──")

	var p = _player_script.new().Player.new()
	p.set_string_val("hello")
	p.set_int32_val(42)
	var _w: PackedByteArray = p.to_bytes()

	var start: int = Time.get_ticks_usec()
	for _i: int in range(SERIALIZE_ITERATIONS):
		_w = p.to_bytes()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("Player.to_bytes() [2 fields]", elapsed, SERIALIZE_ITERATIONS)
	print("    output: %d bytes" % _w.size())


# ── BM 9: Serialize full ──

func bench_serialize_large() -> void:
	print("── BM 9: Serialize full message ──")

	var p = _player_script.new().Player.new()
	p.set_double_val(3.14)
	p.set_float_val(2.71)
	p.set_int32_val(100)
	p.set_int64_val(9999999999)
	p.set_uint32_val(200)
	p.set_uint64_val(8888888888)
	p.set_sint32_val(-50)
	p.set_sint64_val(-99999)
	p.set_fixed32_val(0x7FFFFFFF)
	p.set_fixed64_val(0x7FFFFFFFFFFFFFFF)
	p.set_sfixed32_val(-1000)
	p.set_sfixed64_val(-2000000)
	p.set_bool_val(true)
	p.set_string_val("benchmark string value")
	p.set_bytes_val(PackedByteArray([1, 2, 3, 4, 5]))
	for i: int in range(10):
		p.add_items("item_%d" % i)
	for i: int in range(20):
		p.add_metadata("k%d" % i, "v%d" % i)
	var stats = p.new_stats()
	stats.set_strength(10)
	stats.set_agility(20)
	stats.set_intelligence(30)

	var start: int = Time.get_ticks_usec()
	for _i: int in range(SERIALIZE_ITERATIONS):
		var _ignored: PackedByteArray = p.to_bytes()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("Player.to_bytes() [all fields]", elapsed, SERIALIZE_ITERATIONS)
	var final_bytes: PackedByteArray = p.to_bytes()
	print("    output: %d bytes" % final_bytes.size())


# ── BM 10: Deserialize small ──

func bench_deserialize_small() -> void:
	print("── BM 10: Deserialize small message ──")

	var p = _player_script.new().Player.new()
	p.set_string_val("hello")
	p.set_int32_val(42)
	var data: PackedByteArray = p.to_bytes()

	var start: int = Time.get_ticks_usec()
	for _i: int in range(SERIALIZE_ITERATIONS):
		var px = _player_script.new().Player.new()
		var _r: int = px.from_bytes(data)
	var elapsed: int = Time.get_ticks_usec() - start
	_report("Player.from_bytes() [2 fields]", elapsed, SERIALIZE_ITERATIONS)


# ── BM 11: Deserialize full ──

func bench_deserialize_large() -> void:
	print("── BM 11: Deserialize full message ──")

	var p = _player_script.new().Player.new()
	p.set_double_val(3.14)
	p.set_string_val("benchmark string value")
	p.set_int32_val(100)
	p.set_bool_val(true)
	for i: int in range(10):
		p.add_items("item_%d" % i)
	for i: int in range(20):
		p.add_metadata("k%d" % i, "v%d" % i)
	var stats = p.new_stats()
	stats.set_strength(10)
	stats.set_agility(20)
	stats.set_intelligence(30)
	var data: PackedByteArray = p.to_bytes()

	var start: int = Time.get_ticks_usec()
	for _i: int in range(SERIALIZE_ITERATIONS):
		var px = _player_script.new().Player.new()
		var _r: int = px.from_bytes(data)
	var elapsed: int = Time.get_ticks_usec() - start
	_report("Player.from_bytes() [all fields]", elapsed, SERIALIZE_ITERATIONS)


# ── BM 12: Clear/reset overhead ──

func bench_clear_reset() -> void:
	print("── BM 12: Clear/reset overhead ──")

	var p = _player_script.new().Player.new()
	p.set_string_val("hello world")
	p.set_int32_val(42)

	var start: int = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_string_val("hello world")
		p.clear_string_val()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("set+clear_string_val()", elapsed, ITERATIONS)

	p.new_stats()
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.clear_stats()
	elapsed = Time.get_ticks_usec() - start
	_report("clear_stats()", elapsed, ITERATIONS)


# ── BM 13: Inline defaults (verification that dict lookups are eliminated) ──

func bench_default_values_lookup_vs_inline() -> void:
	print("── BM 13: Inline defaults verification ──")
	print("  (DEFAULT_VALUES_2/3 have been eliminated; defaults are now inline literals)")

	var p = _player_script.new().Player.new()

	# Measure clear+set cycle — no dict lookups involved
	var start: int = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_int32_val(42)
		p.clear_int32_val()
	var elapsed: int = Time.get_ticks_usec() - start
	_report("set+clear_int32_val() [inline 0]", elapsed, ITERATIONS)

	p.set_string_val("test")
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_string_val("test")
		p.clear_string_val()
	elapsed = Time.get_ticks_usec() - start
	_report("set+clear_string_val() [inline \"\"]", elapsed, ITERATIONS)

	p.set_bool_val(true)
	start = Time.get_ticks_usec()
	for _i: int in range(ITERATIONS):
		p.set_bool_val(true)
		p.clear_bool_val()
	elapsed = Time.get_ticks_usec() - start
	_report("set+clear_bool_val() [inline false]", elapsed, ITERATIONS)


# ── BM 14: Script preload overhead (core runtime duplication) ──

func bench_preload_overhead() -> void:
	print("── BM 14: Script preload overhead ──")
	print("  Both player.gd and game.gd embed full core runtime (~700 lines)")

	var start: int = Time.get_ticks_usec()
	for _i: int in range(100):
		var _s1 = load("res://resources/proto/player.gd")
		var _s2 = load("res://resources/proto/game.gd")
	var elapsed: int = Time.get_ticks_usec() - start
	print("  load(player.gd + game.gd) x100: %.2f ms" % (float(elapsed) / 1000.0))

	var s1 = load("res://resources/proto/player.gd")
	var s2 = load("res://resources/proto/game.gd")
	print("  player.gd == game.gd: %s" % str(s1 == s2))
	print("  (false → core runtime exists in two separate scopes)")


# ── Helpers ──

func _report(label: String, elapsed_us: int, iters: int) -> void:
	var per_op: float = float(elapsed_us) / float(iters)
	var total_ms: float = float(elapsed_us) / 1000.0
	print("  %-42s  total=%8.2f ms  per_op=%8.2f us" % [label, total_ms, per_op])


func _finish() -> void:
	print("")
	print("══════════════════════════════════════════════")
	print("  Benchmark complete")
	print("══════════════════════════════════════════════")
	quit(0)
