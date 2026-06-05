extends GutTest

const Player = preload("res://resources/proto/player.gd").Player
const Game = preload("res://resources/proto/game.gd").Game
const PB_ERR_NO_ERRORS = 0


func _read_file(path: String) -> PackedByteArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		fail_test("Cannot open file: " + path)
		return PackedByteArray()
	var data := f.get_buffer(f.get_length())
	f.close()
	return data


func test_python_player_to_godot() -> void:
	var data := _read_file("res://test_data/python_player.bin")
	var p := Player.new()
	var err := p.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS, "Player.from_bytes should succeed")

	assert_true(p.has_double_val())
	assert_almost_eq(p.get_double_val(), 3.14159, 0.0001)
	assert_true(p.has_string_val())
	assert_eq(p.get_string_val(), "cross-test")
	assert_true(p.has_bool_val())
	assert_true(p.get_bool_val())
	assert_true(p.has_int32_val())
	assert_eq(p.get_int32_val(), 42)

	assert_true(p.has_email())
	assert_eq(p.get_email(), "cross@test.com")

	var items := p.get_items()
	assert_eq(items.size(), 3)
	assert_eq(items[0], "alpha")
	assert_eq(items[1], "beta")
	assert_eq(items[2], "gamma")

	assert_true(p.has_stats())
	assert_eq(p.get_stats().get_strength(), 15)
	assert_eq(p.get_stats().get_agility(), 10)
	assert_eq(p.get_stats().get_intelligence(), 8)

	var history := p.get_history()
	assert_eq(history.size(), 2)
	assert_eq(history[0].get_strength(), 5)
	assert_eq(history[1].get_strength(), 7)

	var metadata := p.get_metadata()
	assert_eq(metadata.size(), 2)
	assert_eq(metadata["name"], "protobuf")
	assert_eq(metadata["lang"], "python")

	var labels := p.get_labels()
	assert_eq(labels.size(), 2)
	assert_eq(labels[1], "one")
	assert_eq(labels[2], "two")

	var skills := p.get_skills()
	assert_eq(skills.size(), 2)
	assert_eq(skills["fire"], Player.Skill.FIRE)
	assert_eq(skills["lightning"], Player.Skill.LIGHTNING)


func test_godot_player_to_file() -> void:
	var p := Player.new()
	p.set_double_val(2.71828)
	p.set_float_val(1.414)
	p.set_int32_val(-100)
	p.set_int64_val(-9999)
	p.set_uint32_val(42)
	p.set_uint64_val(4242)
	p.set_sint32_val(-50)
	p.set_sint64_val(-5000)
	p.set_fixed32_val(0xFF)
	p.set_fixed64_val(0xFFFF)
	p.set_sfixed32_val(-0xFF)
	p.set_sfixed64_val(-0xFFFF)
	p.set_bool_val(false)
	p.set_string_val("godot → python")
	p.set_bytes_val(PackedByteArray([0xDE, 0xAD, 0xBE, 0xEF]))
	p.set_class(Player.Class.MAGE)

	p.add_items("x")
	p.add_items("y")

	p.set_phone(9876543210)

	var stats := p.new_stats()
	stats.set_strength(20)
	stats.set_agility(15)
	stats.set_intelligence(10)

	for _i in range(3):
		var s := p.add_history()
		s.set_strength(1)
		s.set_agility(2)
		s.set_intelligence(3)

	p.add_metadata("godot_key", "works")
	p.add_labels(99, "ninety-nine")
	p.add_skills("ice_skill", Player.Skill.ICE)

	var data := p.to_bytes()
	var f := FileAccess.open("res://test_data/godot_player.bin", FileAccess.WRITE)
	if f == null:
		fail_test("Cannot write godot_player.bin")
		return
	f.store_buffer(data)
	f.close()
	assert_true(true, "Wrote godot_player.bin")


func test_python_game_to_godot() -> void:
	var data := _read_file("res://test_data/python_game.bin")
	var g := Game.new()
	var err := g.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS, "Game.from_bytes should succeed")

	assert_eq(g.get_id(), "cross-game")
	assert_eq(g.get_max_players(), 16)
	assert_eq(g.get_started(), true)
	assert_eq(g.get_state(), Game.State.IN_PROGRESS)

	var players := g.get_players()
	assert_eq(players.size(), 2)
	assert_eq(players[0].get_string_val(), "p1")
	assert_eq(players[1].get_string_val(), "p2")

	assert_true(g.has_leader())
	assert_eq(g.get_leader().get_string_val(), "boss")

	assert_true(g.has_config())
	assert_eq(g.get_config().get_friendly_fire(), true)
	assert_eq(g.get_config().get_mode(), Game.Config.Mode.RANKED)

	var rounds := g.get_rounds()
	assert_eq(rounds.size(), 2)


func test_godot_game_to_file() -> void:
	var g := Game.new()
	g.set_id("godot-game")
	g.set_max_players(4)
	g.set_started(false)
	g.set_state(Game.State.LOBBY)

	var p := g.add_players()
	p.set_string_val("gdplayer")

	var leader := g.new_leader()
	leader.set_string_val("gdleader")

	g.set_reward_text("treasure")

	var c := g.new_config()
	c.set_friendly_fire(false)
	c.set_time_limit(120.0)
	c.set_mode(Game.Config.Mode.NORMAL)

	var r := g.add_rounds()
	r.set_time_limit(60.0)
	r.set_mode(Game.Config.Mode.TOURNAMENT)

	var data := g.to_bytes()
	var f := FileAccess.open("res://test_data/godot_game.bin", FileAccess.WRITE)
	if f == null:
		fail_test("Cannot write godot_game.bin")
		return
	f.store_buffer(data)
	f.close()
	assert_true(true, "Wrote godot_game.bin")
