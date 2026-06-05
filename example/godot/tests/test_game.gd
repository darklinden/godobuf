extends GutTest

const Game = preload("res://resources/proto/game.gd").Game
const PB_ERR_NO_ERRORS = 0


func test_game_basic() -> void:
	var g := Game.new()
	g.set_id("game-001")
	g.set_max_players(8)
	g.set_started(true)
	g.set_state(Game.State.LOBBY)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_eq(g2.get_id(), "game-001")
	assert_eq(g2.get_max_players(), 8)
	assert_eq(g2.get_started(), true)
	assert_eq(g2.get_state(), Game.State.LOBBY)


func test_game_with_players() -> void:
	var g := Game.new()
	g.set_id("game-002")

	var p1 := g.add_players()
	p1.set_string_val("alice")
	p1.set_int32_val(100)

	var p2 := g.add_players()
	p2.set_string_val("bob")
	p2.set_int32_val(200)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)

	var players := g2.get_players()
	assert_eq(players.size(), 2)
	assert_eq(players[0].get_string_val(), "alice")
	assert_eq(players[0].get_int32_val(), 100)
	assert_eq(players[1].get_string_val(), "bob")
	assert_eq(players[1].get_int32_val(), 200)


func test_game_optional_leader() -> void:
	var g := Game.new()
	var leader := g.new_leader()
	leader.set_string_val("champion")
	leader.set_int32_val(999)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_true(g2.has_leader())
	assert_eq(g2.get_leader().get_string_val(), "champion")
	assert_eq(g2.get_leader().get_int32_val(), 999)


func test_game_oneof_reward_text() -> void:
	var g := Game.new()
	g.set_reward_text("gold x100")

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_true(g2.has_reward_text())
	assert_false(g2.has_reward_booster())
	assert_eq(g2.get_reward_text(), "gold x100")


func test_game_oneof_reward_booster() -> void:
	var g := Game.new()
	var b := g.new_reward_booster()
	b.set_string_val("super_boost")
	b.set_int32_val(500)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_false(g2.has_reward_text())
	assert_true(g2.has_reward_booster())
	assert_eq(g2.get_reward_booster().get_string_val(), "super_boost")
	assert_eq(g2.get_reward_booster().get_int32_val(), 500)


func test_game_map_team() -> void:
	var g := Game.new()
	var p := g.add_team("red")
	p.set_string_val("player_red")
	p.set_int32_val(10)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	var m := g2.get_team()
	assert_eq(m.size(), 1)
	assert_eq(m["red"].get_string_val(), "player_red")
	assert_eq(m["red"].get_int32_val(), 10)


func test_game_nested_config() -> void:
	var g := Game.new()
	var c := g.new_config()
	c.set_friendly_fire(true)
	c.set_time_limit(300.0)
	c.set_mode(Game.Config.Mode.RANKED)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_true(g2.has_config())
	var c2 := g2.get_config()
	assert_eq(c2.get_friendly_fire(), true)
	assert_eq(c2.get_time_limit(), 300.0)
	assert_eq(c2.get_mode(), Game.Config.Mode.RANKED)


func test_game_repeated_config() -> void:
	var g := Game.new()
	for i in range(2):
		var c := g.add_rounds()
		c.set_friendly_fire(i == 0)
		c.set_time_limit(60.0 * (i + 1))
		c.set_mode(Game.Config.Mode.TOURNAMENT if i == 1 else Game.Config.Mode.NORMAL)

	var data := g.to_bytes()
	var g2 := Game.new()
	var err := g2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)

	var rounds := g2.get_rounds()
	assert_eq(rounds.size(), 2)
	assert_eq(rounds[0].get_friendly_fire(), true)
	assert_eq(rounds[0].get_time_limit(), 60.0)
	assert_eq(rounds[0].get_mode(), Game.Config.Mode.NORMAL)
	assert_eq(rounds[1].get_friendly_fire(), false)
	assert_eq(rounds[1].get_time_limit(), 120.0)
	assert_eq(rounds[1].get_mode(), Game.Config.Mode.TOURNAMENT)
