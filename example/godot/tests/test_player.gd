extends GutTest

const Player = preload("res://resources/proto/player.gd").Player
const PB_ERR_NO_ERRORS = 0


func test_scalar_pack_unpack() -> void:
	var p := Player.new()
	p.set_double_val(3.14)
	p.set_float_val(2.718)
	p.set_int32_val(42)
	p.set_int64_val(-100)
	p.set_uint32_val(255)
	p.set_uint64_val(65535)
	p.set_sint32_val(-50)
	p.set_sint64_val(-200)
	p.set_fixed32_val(12345)
	p.set_fixed64_val(67890)
	p.set_sfixed32_val(-12345)
	p.set_sfixed64_val(-67890)
	p.set_bool_val(true)
	p.set_string_val("hello proto")
	p.set_bytes_val(PackedByteArray([1, 2, 3]))

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)

	assert_true(p2.has_double_val())
	assert_eq(p2.get_double_val(), 3.14)
	assert_true(p2.has_float_val())
	assert_true(p2.has_float_val())
	assert_almost_eq(p2.get_float_val(), 2.718, 0.001)
	assert_eq(p2.get_int32_val(), 42)
	assert_eq(p2.get_int64_val(), -100)
	assert_eq(p2.get_uint32_val(), 255)
	assert_eq(p2.get_uint64_val(), 65535)
	assert_eq(p2.get_sint32_val(), -50)
	assert_eq(p2.get_sint64_val(), -200)
	assert_eq(p2.get_fixed32_val(), 12345)
	assert_eq(p2.get_fixed64_val(), 67890)
	assert_eq(p2.get_sfixed32_val(), -12345)
	assert_eq(p2.get_sfixed64_val(), -67890)
	assert_true(p2.has_bool_val())
	assert_eq(p2.get_bool_val(), true)
	assert_eq(p2.get_string_val(), "hello proto")
	var b2 := p2.get_bytes_val()
	assert_eq(b2.size(), 3)
	assert_eq(b2[0], 1)
	assert_eq(b2[1], 2)
	assert_eq(b2[2], 3)


func test_scalar_defaults() -> void:
	var p := Player.new()
	assert_false(p.has_string_val())
	assert_false(p.has_int32_val())


func test_enum() -> void:
	var p := Player.new()
	p.set_class(Player.Class.WARRIOR)

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_eq(p2.get_class_(), Player.Class.WARRIOR)


func test_repeated_strings() -> void:
	var p := Player.new()
	p.add_items("sword")
	p.add_items("shield")
	p.add_items("potion")

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	var items := p2.get_items()
	assert_eq(items.size(), 3)
	assert_eq(items[0], "sword")
	assert_eq(items[1], "shield")
	assert_eq(items[2], "potion")


func test_oneof_contact() -> void:
	var p := Player.new()
	p.set_email("test@example.com")

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_true(p2.has_email())
	assert_false(p2.has_phone())
	assert_eq(p2.get_email(), "test@example.com")
	assert_eq(p2.get_contact_case(), Player.ContactCase.EMAIL)


func test_oneof_switch() -> void:
	var p := Player.new()
	p.set_email("first@test.com")

	# Switch to phone
	p.set_phone(1234567890)
	assert_false(p.has_email())
	assert_true(p.has_phone())
	assert_eq(p.get_phone(), 1234567890)

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_false(p2.has_email())
	assert_true(p2.has_phone())
	assert_eq(p2.get_phone(), 1234567890)
	assert_eq(p2.get_contact_case(), Player.ContactCase.PHONE)


func test_nested_message() -> void:
	var p := Player.new()
	var stats := p.new_stats()
	stats.set_strength(10)
	stats.set_agility(7)
	stats.set_intelligence(5)

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	assert_true(p2.has_stats())
	var s2 := p2.get_stats()
	assert_eq(s2.get_strength(), 10)
	assert_eq(s2.get_agility(), 7)
	assert_eq(s2.get_intelligence(), 5)


func test_repeated_message() -> void:
	var p := Player.new()
	for i in range(3):
		var s := p.add_history()
		s.set_strength(10 + i)
		s.set_agility(5 + i)
		s.set_intelligence(i)

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	var history := p2.get_history()
	assert_eq(history.size(), 3)
	assert_eq(history[0].get_strength(), 10)
	assert_eq(history[1].get_agility(), 6)
	assert_eq(history[2].get_intelligence(), 2)


func test_map_string_string() -> void:
	var p := Player.new()
	p.add_metadata("key1", "value1")
	p.add_metadata("key2", "value2")

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	var m := p2.get_metadata()
	assert_eq(m.size(), 2)
	assert_eq(m["key1"], "value1")
	assert_eq(m["key2"], "value2")


func test_map_int32_string() -> void:
	var p := Player.new()
	p.add_labels(1, "label_a")
	p.add_labels(2, "label_b")

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	var m := p2.get_labels()
	assert_eq(m.size(), 2)
	assert_eq(m[1], "label_a")
	assert_eq(m[2], "label_b")


func test_map_string_enum() -> void:
	var p := Player.new()
	p.add_skills("fireball", Player.Skill.FIRE)
	p.add_skills("blizzard", Player.Skill.ICE)

	var data := p.to_bytes()
	var p2 := Player.new()
	var err := p2.from_bytes(data)
	assert_eq(err, PB_ERR_NO_ERRORS)
	var m := p2.get_skills()
	assert_eq(m.size(), 2)
	assert_eq(m["fireball"], Player.Skill.FIRE)
	assert_eq(m["blizzard"], Player.Skill.ICE)


func test_empty_message_to_bytes() -> void:
	var p := Player.new()
	var data := p.to_bytes()
	assert_eq(data.size(), 0)


func test_clear_field() -> void:
	var p := Player.new()
	p.set_string_val("test")
	assert_true(p.has_string_val())
	p.clear_string_val()
	assert_false(p.has_string_val())
