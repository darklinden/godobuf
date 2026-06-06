const _C = preload("res://addons/godobuf/godobuf_core.gd")
const PROTO_VERSION: int = 3

const Player = preload("player.gd").Player

class Game:
	extends RefCounted
	func _init() -> void:
		var service: _C.PBServiceField
		
		__id = _C.PBField.new("id", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 1, true, "")
		service = _C.PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __players_default: Array[Player] = []
		__players = _C.PBField.new("players", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.REPEATED, 2, true, __players_default)
		service = _C.PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
		__max_players = _C.PBField.new("max_players", _C.PB_DATA_TYPE.INT32, _C.PB_RULE.OPTIONAL, 3, true, 0)
		service = _C.PBServiceField.new()
		service.field = __max_players
		data[__max_players.tag] = service
		
		__started = _C.PBField.new("started", _C.PB_DATA_TYPE.BOOL, _C.PB_RULE.OPTIONAL, 4, true, false)
		service = _C.PBServiceField.new()
		service.field = __started
		data[__started.tag] = service
		
		__state = _C.PBField.new("state", _C.PB_DATA_TYPE.ENUM, _C.PB_RULE.OPTIONAL, 5, true, 0)
		service = _C.PBServiceField.new()
		service.field = __state
		data[__state.tag] = service
		
		__leader = _C.PBField.new("leader", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.OPTIONAL, 6, true, null)
		service = _C.PBServiceField.new()
		service.field = __leader
		service.func_ref = Callable(self, "new_leader")
		data[__leader.tag] = service
		
		__reward_text = _C.PBField.new("reward_text", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 7, true, "")
		service = _C.PBServiceField.new()
		service.field = __reward_text
		data[__reward_text.tag] = service
		
		__reward_booster = _C.PBField.new("reward_booster", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.OPTIONAL, 8, true, null)
		service = _C.PBServiceField.new()
		service.field = __reward_booster
		service.func_ref = Callable(self, "new_reward_booster")
		data[__reward_booster.tag] = service
		
		var __team_default: Array = []
		__team = _C.PBField.new("team", _C.PB_DATA_TYPE.MAP, _C.PB_RULE.REPEATED, 9, true, __team_default)
		__team.is_map_field = true
		service = _C.PBServiceField.new()
		service.field = __team
		service.func_ref = Callable(self, "add_empty_team")
		data[__team.tag] = service
		
		__config = _C.PBField.new("config", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.OPTIONAL, 10, true, null)
		service = _C.PBServiceField.new()
		service.field = __config
		service.func_ref = Callable(self, "new_config")
		data[__config.tag] = service
		
		var __rounds_default: Array[Game.Config] = []
		__rounds = _C.PBField.new("rounds", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.REPEATED, 11, true, __rounds_default)
		service = _C.PBServiceField.new()
		service.field = __rounds
		service.func_ref = Callable(self, "add_rounds")
		data[__rounds.tag] = service
		
	var data: Dictionary = {}
	
	enum RewardCase {
		REWARD_NOT_SET = 0,
		REWARD_TEXT = 7,
		REWARD_BOOSTER = 8,
	}
	var _reward_case: int = 0

	enum LeaderCase {
		_LEADER_NOT_SET = 0,
		LEADER = 6,
	}
	var __leader_case: int = 0

	var __id: _C.PBField
	func has_id() -> bool:
		return data[1].state == _C.PB_SERVICE_STATE.FILLED
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = _C.PB_SERVICE_STATE.UNFILLED
		__id.value = ""
	func set_id(value : String) -> void:
		data[1].state = _C.PB_SERVICE_STATE.FILLED
		__id.value = value
	
	var __players: _C.PBField
	func get_players() -> Array[Player]:
		return __players.value
	func clear_players() -> void:
		data[2].state = _C.PB_SERVICE_STATE.UNFILLED
		__players.clear_array()
	func add_players() -> Player:
		var element: Player = Player.new()
		__players.append_array(element)
		return element
	
	var __max_players: _C.PBField
	func has_max_players() -> bool:
		return data[3].state == _C.PB_SERVICE_STATE.FILLED
	func get_max_players() -> int:
		return __max_players.value
	func clear_max_players() -> void:
		data[3].state = _C.PB_SERVICE_STATE.UNFILLED
		__max_players.value = 0
	func set_max_players(value : int) -> void:
		data[3].state = _C.PB_SERVICE_STATE.FILLED
		__max_players.value = value
	
	var __started: _C.PBField
	func has_started() -> bool:
		return data[4].state == _C.PB_SERVICE_STATE.FILLED
	func get_started() -> bool:
		return __started.value
	func clear_started() -> void:
		data[4].state = _C.PB_SERVICE_STATE.UNFILLED
		__started.value = false
	func set_started(value : bool) -> void:
		data[4].state = _C.PB_SERVICE_STATE.FILLED
		__started.value = value
	
	var __state: _C.PBField
	func has_state() -> bool:
		return data[5].state == _C.PB_SERVICE_STATE.FILLED
	func get_state() -> int:
		return __state.value
	func clear_state() -> void:
		data[5].state = _C.PB_SERVICE_STATE.UNFILLED
		__state.value = 0
	func set_state(value : int) -> void:
		data[5].state = _C.PB_SERVICE_STATE.FILLED
		__state.value = value
	
	var __leader: _C.PBField
	func has_leader() -> bool:
		return data[6].state == _C.PB_SERVICE_STATE.FILLED
	func get_leader() -> Player:
		return __leader.value
	func clear_leader() -> void:
		data[6].state = _C.PB_SERVICE_STATE.UNFILLED
		__leader_case = 0
		__leader.value = null
	func new_leader() -> Player:
		data[6].state = _C.PB_SERVICE_STATE.FILLED
		__leader_case = 6
		__leader.value = Player.new()
		return __leader.value
	
	var __reward_text: _C.PBField
	func has_reward_text() -> bool:
		return data[7].state == _C.PB_SERVICE_STATE.FILLED
	func get_reward_text() -> String:
		return __reward_text.value
	func clear_reward_text() -> void:
		data[7].state = _C.PB_SERVICE_STATE.UNFILLED
		_reward_case = 0
		__reward_text.value = ""
	func set_reward_text(value : String) -> void:
		data[7].state = _C.PB_SERVICE_STATE.FILLED
		_reward_case = 7
		__reward_booster.value = null
		data[8].state = _C.PB_SERVICE_STATE.UNFILLED
		__reward_text.value = value
	
	var __reward_booster: _C.PBField
	func has_reward_booster() -> bool:
		return data[8].state == _C.PB_SERVICE_STATE.FILLED
	func get_reward_booster() -> Player:
		return __reward_booster.value
	func clear_reward_booster() -> void:
		data[8].state = _C.PB_SERVICE_STATE.UNFILLED
		_reward_case = 0
		__reward_booster.value = null
	func new_reward_booster() -> Player:
		__reward_text.value = ""
		data[7].state = _C.PB_SERVICE_STATE.UNFILLED
		data[8].state = _C.PB_SERVICE_STATE.FILLED
		_reward_case = 8
		__reward_booster.value = Player.new()
		return __reward_booster.value
	
	var __team: _C.PBField
	var __team_cached: Dictionary = {}
	var __team_cache_valid: bool = false
	func get_raw_team() -> Variant:
		return __team.value
	func get_team() -> Dictionary:
		if not __team_cache_valid:
			__team_cached = _C.PBPacker.construct_map(__team.as_array())
			__team_cache_valid = true
		return __team_cached
	func clear_team() -> void:
		__team_cache_valid = false
		data[9].state = _C.PB_SERVICE_STATE.UNFILLED
		__team.clear_array()
	func add_empty_team() -> Game.map_type_team:
		__team_cache_valid = false
		var element: Game.map_type_team = Game.map_type_team.new()
		__team.append_array(element)
		return element
	func add_team(a_key: String) -> Player:
		__team_cache_valid = false
		var idx: int = __team.find_map_index(a_key)
		var element: Game.map_type_team = Game.map_type_team.new()
		element.set_key(a_key)
		if idx != -1:
			__team.set_map_element(idx, element)
		else:
			__team.append_array(element)
		return element.new_value()
	
	var __config: _C.PBField
	func has_config() -> bool:
		if __config.value != null:
			return true
		return false
	func get_config() -> Game.Config:
		return __config.value
	func clear_config() -> void:
		data[10].state = _C.PB_SERVICE_STATE.UNFILLED
		__config.value = null
	func new_config() -> Game.Config:
		__config.value = Game.Config.new()
		return __config.value
	
	var __rounds: _C.PBField
	func get_rounds() -> Array[Game.Config]:
		return __rounds.value
	func clear_rounds() -> void:
		data[11].state = _C.PB_SERVICE_STATE.UNFILLED
		__rounds.clear_array()
	func add_rounds() -> Game.Config:
		var element: Game.Config = Game.Config.new()
		__rounds.append_array(element)
		return element
	
	func get_reward_case() -> int:
		return _reward_case
	func get__leader_case() -> int:
		return __leader_case
	enum State {
		UNKNOWN = 0,
		LOBBY = 1,
		IN_PROGRESS = 2,
		FINISHED = 3
	}
	
	class map_type_team:
		extends RefCounted
		func _init() -> void:
			var service: _C.PBServiceField
			
			__key = _C.PBField.new("key", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 1, true, "")
			service = _C.PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = _C.PBField.new("value", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.OPTIONAL, 2, true, null)
			service = _C.PBServiceField.new()
			service.field = __value
			service.func_ref = Callable(self, "new_value")
			data[__value.tag] = service
			
		var data: Dictionary = {}
		
		var __key: _C.PBField
		func has_key() -> bool:
			return data[1].state == _C.PB_SERVICE_STATE.FILLED
		func get_key() -> String:
			return __key.value
		func clear_key() -> void:
			data[1].state = _C.PB_SERVICE_STATE.UNFILLED
			__key.value = ""
		func set_key(value : String) -> void:
			data[1].state = _C.PB_SERVICE_STATE.FILLED
			__key.value = value
		
		var __value: _C.PBField
		func has_value() -> bool:
			if __value.value != null:
				return true
			return false
		func get_value() -> Player:
			return __value.value
		func clear_value() -> void:
			data[2].state = _C.PB_SERVICE_STATE.UNFILLED
			__value.value = null
		func new_value() -> Player:
			__value.value = Player.new()
			return __value.value
		
		func _to_string() -> String:
			return _C.PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return _C.PBPacker.pack_message(data, PROTO_VERSION)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit: int = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result: int = _C.PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if _C.PBPacker.check_required(data):
					if limit == -1:
						return _C.PB_ERR.NO_ERRORS
				else:
					return _C.PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return _C.PB_ERR.PARSE_INCOMPLETE
			return result
		
	class Config:
		extends RefCounted
		func _init() -> void:
			var service: _C.PBServiceField
			
			__friendly_fire = _C.PBField.new("friendly_fire", _C.PB_DATA_TYPE.BOOL, _C.PB_RULE.OPTIONAL, 1, true, false)
			service = _C.PBServiceField.new()
			service.field = __friendly_fire
			data[__friendly_fire.tag] = service
			
			__time_limit = _C.PBField.new("time_limit", _C.PB_DATA_TYPE.FLOAT, _C.PB_RULE.OPTIONAL, 2, true, 0.0)
			service = _C.PBServiceField.new()
			service.field = __time_limit
			data[__time_limit.tag] = service
			
			__mode = _C.PBField.new("mode", _C.PB_DATA_TYPE.ENUM, _C.PB_RULE.OPTIONAL, 3, true, 0)
			service = _C.PBServiceField.new()
			service.field = __mode
			data[__mode.tag] = service
			
		var data: Dictionary = {}
		
		var __friendly_fire: _C.PBField
		func has_friendly_fire() -> bool:
			return data[1].state == _C.PB_SERVICE_STATE.FILLED
		func get_friendly_fire() -> bool:
			return __friendly_fire.value
		func clear_friendly_fire() -> void:
			data[1].state = _C.PB_SERVICE_STATE.UNFILLED
			__friendly_fire.value = false
		func set_friendly_fire(value : bool) -> void:
			data[1].state = _C.PB_SERVICE_STATE.FILLED
			__friendly_fire.value = value
		
		var __time_limit: _C.PBField
		func has_time_limit() -> bool:
			return data[2].state == _C.PB_SERVICE_STATE.FILLED
		func get_time_limit() -> float:
			return __time_limit.value
		func clear_time_limit() -> void:
			data[2].state = _C.PB_SERVICE_STATE.UNFILLED
			__time_limit.value = 0.0
		func set_time_limit(value : float) -> void:
			data[2].state = _C.PB_SERVICE_STATE.FILLED
			__time_limit.value = value
		
		var __mode: _C.PBField
		func has_mode() -> bool:
			return data[3].state == _C.PB_SERVICE_STATE.FILLED
		func get_mode() -> int:
			return __mode.value
		func clear_mode() -> void:
			data[3].state = _C.PB_SERVICE_STATE.UNFILLED
			__mode.value = 0
		func set_mode(value : int) -> void:
			data[3].state = _C.PB_SERVICE_STATE.FILLED
			__mode.value = value
		
		enum Mode {
			NORMAL = 0,
			RANKED = 1,
			TOURNAMENT = 2
		}
		
		func _to_string() -> String:
			return _C.PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return _C.PBPacker.pack_message(data, PROTO_VERSION)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit: int = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result: int = _C.PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if _C.PBPacker.check_required(data):
					if limit == -1:
						return _C.PB_ERR.NO_ERRORS
				else:
					return _C.PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return _C.PB_ERR.PARSE_INCOMPLETE
			return result
	
	func _to_string() -> String:
		return _C.PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return _C.PBPacker.pack_message(data, PROTO_VERSION)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit: int = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result: int = _C.PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			_reward_case = 0
			if data[7].state == _C.PB_SERVICE_STATE.FILLED:
				_reward_case = 7
			if data[8].state == _C.PB_SERVICE_STATE.FILLED:
				_reward_case = 8
			__leader_case = 0
			if data[6].state == _C.PB_SERVICE_STATE.FILLED:
				__leader_case = 6
			if _C.PBPacker.check_required(data):
				if limit == -1:
					return _C.PB_ERR.NO_ERRORS
			else:
				return _C.PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return _C.PB_ERR.PARSE_INCOMPLETE
		return result

