const _C = preload("res://addons/godobuf/godobuf_core.gd")
const PROTO_VERSION: int = 3

class Player:
	extends RefCounted
	func _init() -> void:
		var service: _C.PBServiceField
		
		__double_val = _C.PBField.new("double_val", _C.PB_DATA_TYPE.DOUBLE, _C.PB_RULE.OPTIONAL, 1, true, 0.0)
		service = _C.PBServiceField.new()
		service.field = __double_val
		data[__double_val.tag] = service
		
		__float_val = _C.PBField.new("float_val", _C.PB_DATA_TYPE.FLOAT, _C.PB_RULE.OPTIONAL, 2, true, 0.0)
		service = _C.PBServiceField.new()
		service.field = __float_val
		data[__float_val.tag] = service
		
		__int32_val = _C.PBField.new("int32_val", _C.PB_DATA_TYPE.INT32, _C.PB_RULE.OPTIONAL, 3, true, 0)
		service = _C.PBServiceField.new()
		service.field = __int32_val
		data[__int32_val.tag] = service
		
		__int64_val = _C.PBField.new("int64_val", _C.PB_DATA_TYPE.INT64, _C.PB_RULE.OPTIONAL, 4, true, 0)
		service = _C.PBServiceField.new()
		service.field = __int64_val
		data[__int64_val.tag] = service
		
		__uint32_val = _C.PBField.new("uint32_val", _C.PB_DATA_TYPE.UINT32, _C.PB_RULE.OPTIONAL, 5, true, 0)
		service = _C.PBServiceField.new()
		service.field = __uint32_val
		data[__uint32_val.tag] = service
		
		__uint64_val = _C.PBField.new("uint64_val", _C.PB_DATA_TYPE.UINT64, _C.PB_RULE.OPTIONAL, 6, true, 0)
		service = _C.PBServiceField.new()
		service.field = __uint64_val
		data[__uint64_val.tag] = service
		
		__sint32_val = _C.PBField.new("sint32_val", _C.PB_DATA_TYPE.SINT32, _C.PB_RULE.OPTIONAL, 7, true, 0)
		service = _C.PBServiceField.new()
		service.field = __sint32_val
		data[__sint32_val.tag] = service
		
		__sint64_val = _C.PBField.new("sint64_val", _C.PB_DATA_TYPE.SINT64, _C.PB_RULE.OPTIONAL, 8, true, 0)
		service = _C.PBServiceField.new()
		service.field = __sint64_val
		data[__sint64_val.tag] = service
		
		__fixed32_val = _C.PBField.new("fixed32_val", _C.PB_DATA_TYPE.FIXED32, _C.PB_RULE.OPTIONAL, 9, true, 0)
		service = _C.PBServiceField.new()
		service.field = __fixed32_val
		data[__fixed32_val.tag] = service
		
		__fixed64_val = _C.PBField.new("fixed64_val", _C.PB_DATA_TYPE.FIXED64, _C.PB_RULE.OPTIONAL, 10, true, 0)
		service = _C.PBServiceField.new()
		service.field = __fixed64_val
		data[__fixed64_val.tag] = service
		
		__sfixed32_val = _C.PBField.new("sfixed32_val", _C.PB_DATA_TYPE.SFIXED32, _C.PB_RULE.OPTIONAL, 11, true, 0)
		service = _C.PBServiceField.new()
		service.field = __sfixed32_val
		data[__sfixed32_val.tag] = service
		
		__sfixed64_val = _C.PBField.new("sfixed64_val", _C.PB_DATA_TYPE.SFIXED64, _C.PB_RULE.OPTIONAL, 12, true, 0)
		service = _C.PBServiceField.new()
		service.field = __sfixed64_val
		data[__sfixed64_val.tag] = service
		
		__bool_val = _C.PBField.new("bool_val", _C.PB_DATA_TYPE.BOOL, _C.PB_RULE.OPTIONAL, 13, true, false)
		service = _C.PBServiceField.new()
		service.field = __bool_val
		data[__bool_val.tag] = service
		
		__string_val = _C.PBField.new("string_val", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 14, true, "")
		service = _C.PBServiceField.new()
		service.field = __string_val
		data[__string_val.tag] = service
		
		__bytes_val = _C.PBField.new("bytes_val", _C.PB_DATA_TYPE.BYTES, _C.PB_RULE.OPTIONAL, 15, true, [])
		service = _C.PBServiceField.new()
		service.field = __bytes_val
		data[__bytes_val.tag] = service
		
		__class = _C.PBField.new("class", _C.PB_DATA_TYPE.ENUM, _C.PB_RULE.OPTIONAL, 16, true, 0)
		service = _C.PBServiceField.new()
		service.field = __class
		data[__class.tag] = service
		
		var __items_default: Array[String] = []
		__items = _C.PBField.new("items", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.REPEATED, 17, true, __items_default)
		service = _C.PBServiceField.new()
		service.field = __items
		data[__items.tag] = service
		
		__email = _C.PBField.new("email", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 18, true, "")
		service = _C.PBServiceField.new()
		service.field = __email
		data[__email.tag] = service
		
		__phone = _C.PBField.new("phone", _C.PB_DATA_TYPE.INT64, _C.PB_RULE.OPTIONAL, 19, true, 0)
		service = _C.PBServiceField.new()
		service.field = __phone
		data[__phone.tag] = service
		
		__stats = _C.PBField.new("stats", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.OPTIONAL, 20, true, null)
		service = _C.PBServiceField.new()
		service.field = __stats
		service.func_ref = Callable(self, "new_stats")
		data[__stats.tag] = service
		
		var __history_default: Array[Player.Stats] = []
		__history = _C.PBField.new("history", _C.PB_DATA_TYPE.MESSAGE, _C.PB_RULE.REPEATED, 21, true, __history_default)
		service = _C.PBServiceField.new()
		service.field = __history
		service.func_ref = Callable(self, "add_history")
		data[__history.tag] = service
		
		var __metadata_default: Array = []
		__metadata = _C.PBField.new("metadata", _C.PB_DATA_TYPE.MAP, _C.PB_RULE.REPEATED, 22, true, __metadata_default)
		__metadata.is_map_field = true
		service = _C.PBServiceField.new()
		service.field = __metadata
		service.func_ref = Callable(self, "add_empty_metadata")
		data[__metadata.tag] = service
		
		var __labels_default: Array = []
		__labels = _C.PBField.new("labels", _C.PB_DATA_TYPE.MAP, _C.PB_RULE.REPEATED, 23, true, __labels_default)
		__labels.is_map_field = true
		service = _C.PBServiceField.new()
		service.field = __labels
		service.func_ref = Callable(self, "add_empty_labels")
		data[__labels.tag] = service
		
		var __skills_default: Array = []
		__skills = _C.PBField.new("skills", _C.PB_DATA_TYPE.MAP, _C.PB_RULE.REPEATED, 24, true, __skills_default)
		__skills.is_map_field = true
		service = _C.PBServiceField.new()
		service.field = __skills
		service.func_ref = Callable(self, "add_empty_skills")
		data[__skills.tag] = service
		
	var data: Dictionary = {}
	
	enum ContactCase {
		CONTACT_NOT_SET = 0,
		EMAIL = 18,
		PHONE = 19,
	}
	var _contact_case: int = 0

	var __double_val: _C.PBField
	func has_double_val() -> bool:
		return data[1].state == _C.PB_SERVICE_STATE.FILLED
	func get_double_val() -> float:
		return __double_val.value
	func clear_double_val() -> void:
		data[1].state = _C.PB_SERVICE_STATE.UNFILLED
		__double_val.value = 0.0
	func set_double_val(value : float) -> void:
		data[1].state = _C.PB_SERVICE_STATE.FILLED
		__double_val.value = value
	
	var __float_val: _C.PBField
	func has_float_val() -> bool:
		return data[2].state == _C.PB_SERVICE_STATE.FILLED
	func get_float_val() -> float:
		return __float_val.value
	func clear_float_val() -> void:
		data[2].state = _C.PB_SERVICE_STATE.UNFILLED
		__float_val.value = 0.0
	func set_float_val(value : float) -> void:
		data[2].state = _C.PB_SERVICE_STATE.FILLED
		__float_val.value = value
	
	var __int32_val: _C.PBField
	func has_int32_val() -> bool:
		return data[3].state == _C.PB_SERVICE_STATE.FILLED
	func get_int32_val() -> int:
		return __int32_val.value
	func clear_int32_val() -> void:
		data[3].state = _C.PB_SERVICE_STATE.UNFILLED
		__int32_val.value = 0
	func set_int32_val(value : int) -> void:
		data[3].state = _C.PB_SERVICE_STATE.FILLED
		__int32_val.value = value
	
	var __int64_val: _C.PBField
	func has_int64_val() -> bool:
		return data[4].state == _C.PB_SERVICE_STATE.FILLED
	func get_int64_val() -> int:
		return __int64_val.value
	func clear_int64_val() -> void:
		data[4].state = _C.PB_SERVICE_STATE.UNFILLED
		__int64_val.value = 0
	func set_int64_val(value : int) -> void:
		data[4].state = _C.PB_SERVICE_STATE.FILLED
		__int64_val.value = value
	
	var __uint32_val: _C.PBField
	func has_uint32_val() -> bool:
		return data[5].state == _C.PB_SERVICE_STATE.FILLED
	func get_uint32_val() -> int:
		return __uint32_val.value
	func clear_uint32_val() -> void:
		data[5].state = _C.PB_SERVICE_STATE.UNFILLED
		__uint32_val.value = 0
	func set_uint32_val(value : int) -> void:
		data[5].state = _C.PB_SERVICE_STATE.FILLED
		__uint32_val.value = value
	
	var __uint64_val: _C.PBField
	func has_uint64_val() -> bool:
		return data[6].state == _C.PB_SERVICE_STATE.FILLED
	func get_uint64_val() -> int:
		return __uint64_val.value
	func clear_uint64_val() -> void:
		data[6].state = _C.PB_SERVICE_STATE.UNFILLED
		__uint64_val.value = 0
	func set_uint64_val(value : int) -> void:
		data[6].state = _C.PB_SERVICE_STATE.FILLED
		__uint64_val.value = value
	
	var __sint32_val: _C.PBField
	func has_sint32_val() -> bool:
		return data[7].state == _C.PB_SERVICE_STATE.FILLED
	func get_sint32_val() -> int:
		return __sint32_val.value
	func clear_sint32_val() -> void:
		data[7].state = _C.PB_SERVICE_STATE.UNFILLED
		__sint32_val.value = 0
	func set_sint32_val(value : int) -> void:
		data[7].state = _C.PB_SERVICE_STATE.FILLED
		__sint32_val.value = value
	
	var __sint64_val: _C.PBField
	func has_sint64_val() -> bool:
		return data[8].state == _C.PB_SERVICE_STATE.FILLED
	func get_sint64_val() -> int:
		return __sint64_val.value
	func clear_sint64_val() -> void:
		data[8].state = _C.PB_SERVICE_STATE.UNFILLED
		__sint64_val.value = 0
	func set_sint64_val(value : int) -> void:
		data[8].state = _C.PB_SERVICE_STATE.FILLED
		__sint64_val.value = value
	
	var __fixed32_val: _C.PBField
	func has_fixed32_val() -> bool:
		return data[9].state == _C.PB_SERVICE_STATE.FILLED
	func get_fixed32_val() -> int:
		return __fixed32_val.value
	func clear_fixed32_val() -> void:
		data[9].state = _C.PB_SERVICE_STATE.UNFILLED
		__fixed32_val.value = 0
	func set_fixed32_val(value : int) -> void:
		data[9].state = _C.PB_SERVICE_STATE.FILLED
		__fixed32_val.value = value
	
	var __fixed64_val: _C.PBField
	func has_fixed64_val() -> bool:
		return data[10].state == _C.PB_SERVICE_STATE.FILLED
	func get_fixed64_val() -> int:
		return __fixed64_val.value
	func clear_fixed64_val() -> void:
		data[10].state = _C.PB_SERVICE_STATE.UNFILLED
		__fixed64_val.value = 0
	func set_fixed64_val(value : int) -> void:
		data[10].state = _C.PB_SERVICE_STATE.FILLED
		__fixed64_val.value = value
	
	var __sfixed32_val: _C.PBField
	func has_sfixed32_val() -> bool:
		return data[11].state == _C.PB_SERVICE_STATE.FILLED
	func get_sfixed32_val() -> int:
		return __sfixed32_val.value
	func clear_sfixed32_val() -> void:
		data[11].state = _C.PB_SERVICE_STATE.UNFILLED
		__sfixed32_val.value = 0
	func set_sfixed32_val(value : int) -> void:
		data[11].state = _C.PB_SERVICE_STATE.FILLED
		__sfixed32_val.value = value
	
	var __sfixed64_val: _C.PBField
	func has_sfixed64_val() -> bool:
		return data[12].state == _C.PB_SERVICE_STATE.FILLED
	func get_sfixed64_val() -> int:
		return __sfixed64_val.value
	func clear_sfixed64_val() -> void:
		data[12].state = _C.PB_SERVICE_STATE.UNFILLED
		__sfixed64_val.value = 0
	func set_sfixed64_val(value : int) -> void:
		data[12].state = _C.PB_SERVICE_STATE.FILLED
		__sfixed64_val.value = value
	
	var __bool_val: _C.PBField
	func has_bool_val() -> bool:
		return data[13].state == _C.PB_SERVICE_STATE.FILLED
	func get_bool_val() -> bool:
		return __bool_val.value
	func clear_bool_val() -> void:
		data[13].state = _C.PB_SERVICE_STATE.UNFILLED
		__bool_val.value = false
	func set_bool_val(value : bool) -> void:
		data[13].state = _C.PB_SERVICE_STATE.FILLED
		__bool_val.value = value
	
	var __string_val: _C.PBField
	func has_string_val() -> bool:
		return data[14].state == _C.PB_SERVICE_STATE.FILLED
	func get_string_val() -> String:
		return __string_val.value
	func clear_string_val() -> void:
		data[14].state = _C.PB_SERVICE_STATE.UNFILLED
		__string_val.value = ""
	func set_string_val(value : String) -> void:
		data[14].state = _C.PB_SERVICE_STATE.FILLED
		__string_val.value = value
	
	var __bytes_val: _C.PBField
	func has_bytes_val() -> bool:
		return data[15].state == _C.PB_SERVICE_STATE.FILLED
	func get_bytes_val() -> PackedByteArray:
		return __bytes_val.value
	func clear_bytes_val() -> void:
		data[15].state = _C.PB_SERVICE_STATE.UNFILLED
		__bytes_val.value = []
	func set_bytes_val(value : PackedByteArray) -> void:
		data[15].state = _C.PB_SERVICE_STATE.FILLED
		__bytes_val.value = value
	
	var __class: _C.PBField
	func has_class() -> bool:
		return data[16].state == _C.PB_SERVICE_STATE.FILLED
	func get_class_() -> int:
		return __class.value
	func clear_class() -> void:
		data[16].state = _C.PB_SERVICE_STATE.UNFILLED
		__class.value = 0
	func set_class(value : int) -> void:
		data[16].state = _C.PB_SERVICE_STATE.FILLED
		__class.value = value
	
	var __items: _C.PBField
	func get_items() -> Array[String]:
		return __items.value
	func clear_items() -> void:
		data[17].state = _C.PB_SERVICE_STATE.UNFILLED
		__items.clear_array()
	func add_items(value : String) -> void:
		__items.append_array(value)
	
	var __email: _C.PBField
	func has_email() -> bool:
		return data[18].state == _C.PB_SERVICE_STATE.FILLED
	func get_email() -> String:
		return __email.value
	func clear_email() -> void:
		data[18].state = _C.PB_SERVICE_STATE.UNFILLED
		_contact_case = 0
		__email.value = ""
	func set_email(value : String) -> void:
		data[18].state = _C.PB_SERVICE_STATE.FILLED
		_contact_case = 18
		__phone.value = 0
		data[19].state = _C.PB_SERVICE_STATE.UNFILLED
		__email.value = value
	
	var __phone: _C.PBField
	func has_phone() -> bool:
		return data[19].state == _C.PB_SERVICE_STATE.FILLED
	func get_phone() -> int:
		return __phone.value
	func clear_phone() -> void:
		data[19].state = _C.PB_SERVICE_STATE.UNFILLED
		_contact_case = 0
		__phone.value = 0
	func set_phone(value : int) -> void:
		__email.value = ""
		data[18].state = _C.PB_SERVICE_STATE.UNFILLED
		data[19].state = _C.PB_SERVICE_STATE.FILLED
		_contact_case = 19
		__phone.value = value
	
	var __stats: _C.PBField
	func has_stats() -> bool:
		if __stats.value != null:
			return true
		return false
	func get_stats() -> Player.Stats:
		return __stats.value
	func clear_stats() -> void:
		data[20].state = _C.PB_SERVICE_STATE.UNFILLED
		__stats.value = null
	func new_stats() -> Player.Stats:
		__stats.value = Player.Stats.new()
		return __stats.value
	
	var __history: _C.PBField
	func get_history() -> Array[Player.Stats]:
		return __history.value
	func clear_history() -> void:
		data[21].state = _C.PB_SERVICE_STATE.UNFILLED
		__history.clear_array()
	func add_history() -> Player.Stats:
		var element: Player.Stats = Player.Stats.new()
		__history.append_array(element)
		return element
	
	var __metadata: _C.PBField
	var __metadata_cached: Dictionary = {}
	var __metadata_cache_valid: bool = false
	func get_raw_metadata() -> Variant:
		return __metadata.value
	func get_metadata() -> Dictionary:
		if not __metadata_cache_valid:
			__metadata_cached = _C.PBPacker.construct_map(__metadata.as_array())
			__metadata_cache_valid = true
		return __metadata_cached
	func clear_metadata() -> void:
		__metadata_cache_valid = false
		data[22].state = _C.PB_SERVICE_STATE.UNFILLED
		__metadata.clear_array()
	func add_empty_metadata() -> Player.map_type_metadata:
		__metadata_cache_valid = false
		var element: Player.map_type_metadata = Player.map_type_metadata.new()
		__metadata.append_array(element)
		return element
	func add_metadata(a_key: String, a_value: String) -> void:
		__metadata_cache_valid = false
		var idx: int = __metadata.find_map_index(a_key)
		var element: Player.map_type_metadata = Player.map_type_metadata.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			__metadata.set_map_element(idx, element)
		else:
			__metadata.append_array(element)
	
	var __labels: _C.PBField
	var __labels_cached: Dictionary = {}
	var __labels_cache_valid: bool = false
	func get_raw_labels() -> Variant:
		return __labels.value
	func get_labels() -> Dictionary:
		if not __labels_cache_valid:
			__labels_cached = _C.PBPacker.construct_map(__labels.as_array())
			__labels_cache_valid = true
		return __labels_cached
	func clear_labels() -> void:
		__labels_cache_valid = false
		data[23].state = _C.PB_SERVICE_STATE.UNFILLED
		__labels.clear_array()
	func add_empty_labels() -> Player.map_type_labels:
		__labels_cache_valid = false
		var element: Player.map_type_labels = Player.map_type_labels.new()
		__labels.append_array(element)
		return element
	func add_labels(a_key: int, a_value: String) -> void:
		__labels_cache_valid = false
		var idx: int = __labels.find_map_index(a_key)
		var element: Player.map_type_labels = Player.map_type_labels.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			__labels.set_map_element(idx, element)
		else:
			__labels.append_array(element)
	
	var __skills: _C.PBField
	var __skills_cached: Dictionary = {}
	var __skills_cache_valid: bool = false
	func get_raw_skills() -> Variant:
		return __skills.value
	func get_skills() -> Dictionary:
		if not __skills_cache_valid:
			__skills_cached = _C.PBPacker.construct_map(__skills.as_array())
			__skills_cache_valid = true
		return __skills_cached
	func clear_skills() -> void:
		__skills_cache_valid = false
		data[24].state = _C.PB_SERVICE_STATE.UNFILLED
		__skills.clear_array()
	func add_empty_skills() -> Player.map_type_skills:
		__skills_cache_valid = false
		var element: Player.map_type_skills = Player.map_type_skills.new()
		__skills.append_array(element)
		return element
	func add_skills(a_key: String, a_value: int) -> void:
		__skills_cache_valid = false
		var idx: int = __skills.find_map_index(a_key)
		var element: Player.map_type_skills = Player.map_type_skills.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			__skills.set_map_element(idx, element)
		else:
			__skills.append_array(element)
	
	func get_contact_case() -> int:
		return _contact_case
	enum Class {
		UNKNOWN = 0,
		WARRIOR = 1,
		MAGE = 2,
		ROGUE = 3,
		CLERIC = 4
	}
	
	enum Skill {
		NONE = 0,
		FIRE = 1,
		ICE = 2,
		LIGHTNING = 3
	}
	
	class Stats:
		extends RefCounted
		func _init() -> void:
			var service: _C.PBServiceField
			
			__strength = _C.PBField.new("strength", _C.PB_DATA_TYPE.INT32, _C.PB_RULE.OPTIONAL, 1, true, 0)
			service = _C.PBServiceField.new()
			service.field = __strength
			data[__strength.tag] = service
			
			__agility = _C.PBField.new("agility", _C.PB_DATA_TYPE.INT32, _C.PB_RULE.OPTIONAL, 2, true, 0)
			service = _C.PBServiceField.new()
			service.field = __agility
			data[__agility.tag] = service
			
			__intelligence = _C.PBField.new("intelligence", _C.PB_DATA_TYPE.INT32, _C.PB_RULE.OPTIONAL, 3, true, 0)
			service = _C.PBServiceField.new()
			service.field = __intelligence
			data[__intelligence.tag] = service
			
		var data: Dictionary = {}
		
		var __strength: _C.PBField
		func has_strength() -> bool:
			return data[1].state == _C.PB_SERVICE_STATE.FILLED
		func get_strength() -> int:
			return __strength.value
		func clear_strength() -> void:
			data[1].state = _C.PB_SERVICE_STATE.UNFILLED
			__strength.value = 0
		func set_strength(value : int) -> void:
			data[1].state = _C.PB_SERVICE_STATE.FILLED
			__strength.value = value
		
		var __agility: _C.PBField
		func has_agility() -> bool:
			return data[2].state == _C.PB_SERVICE_STATE.FILLED
		func get_agility() -> int:
			return __agility.value
		func clear_agility() -> void:
			data[2].state = _C.PB_SERVICE_STATE.UNFILLED
			__agility.value = 0
		func set_agility(value : int) -> void:
			data[2].state = _C.PB_SERVICE_STATE.FILLED
			__agility.value = value
		
		var __intelligence: _C.PBField
		func has_intelligence() -> bool:
			return data[3].state == _C.PB_SERVICE_STATE.FILLED
		func get_intelligence() -> int:
			return __intelligence.value
		func clear_intelligence() -> void:
			data[3].state = _C.PB_SERVICE_STATE.UNFILLED
			__intelligence.value = 0
		func set_intelligence(value : int) -> void:
			data[3].state = _C.PB_SERVICE_STATE.FILLED
			__intelligence.value = value
		
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
		
	class map_type_metadata:
		extends RefCounted
		func _init() -> void:
			var service: _C.PBServiceField
			
			__key = _C.PBField.new("key", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 1, true, "")
			service = _C.PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = _C.PBField.new("value", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 2, true, "")
			service = _C.PBServiceField.new()
			service.field = __value
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
			return data[2].state == _C.PB_SERVICE_STATE.FILLED
		func get_value() -> String:
			return __value.value
		func clear_value() -> void:
			data[2].state = _C.PB_SERVICE_STATE.UNFILLED
			__value.value = ""
		func set_value(value : String) -> void:
			data[2].state = _C.PB_SERVICE_STATE.FILLED
			__value.value = value
		
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
		
	class map_type_labels:
		extends RefCounted
		func _init() -> void:
			var service: _C.PBServiceField
			
			__key = _C.PBField.new("key", _C.PB_DATA_TYPE.INT32, _C.PB_RULE.OPTIONAL, 1, true, 0)
			service = _C.PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = _C.PBField.new("value", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 2, true, "")
			service = _C.PBServiceField.new()
			service.field = __value
			data[__value.tag] = service
			
		var data: Dictionary = {}
		
		var __key: _C.PBField
		func has_key() -> bool:
			return data[1].state == _C.PB_SERVICE_STATE.FILLED
		func get_key() -> int:
			return __key.value
		func clear_key() -> void:
			data[1].state = _C.PB_SERVICE_STATE.UNFILLED
			__key.value = 0
		func set_key(value : int) -> void:
			data[1].state = _C.PB_SERVICE_STATE.FILLED
			__key.value = value
		
		var __value: _C.PBField
		func has_value() -> bool:
			return data[2].state == _C.PB_SERVICE_STATE.FILLED
		func get_value() -> String:
			return __value.value
		func clear_value() -> void:
			data[2].state = _C.PB_SERVICE_STATE.UNFILLED
			__value.value = ""
		func set_value(value : String) -> void:
			data[2].state = _C.PB_SERVICE_STATE.FILLED
			__value.value = value
		
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
		
	class map_type_skills:
		extends RefCounted
		func _init() -> void:
			var service: _C.PBServiceField
			
			__key = _C.PBField.new("key", _C.PB_DATA_TYPE.STRING, _C.PB_RULE.OPTIONAL, 1, true, "")
			service = _C.PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = _C.PBField.new("value", _C.PB_DATA_TYPE.ENUM, _C.PB_RULE.OPTIONAL, 2, true, 0)
			service = _C.PBServiceField.new()
			service.field = __value
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
			return data[2].state == _C.PB_SERVICE_STATE.FILLED
		func get_value() -> int:
			return __value.value
		func clear_value() -> void:
			data[2].state = _C.PB_SERVICE_STATE.UNFILLED
			__value.value = 0
		func set_value(value : int) -> void:
			data[2].state = _C.PB_SERVICE_STATE.FILLED
			__value.value = value
		
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
			_contact_case = 0
			if data[18].state == _C.PB_SERVICE_STATE.FILLED:
				_contact_case = 18
			if data[19].state == _C.PB_SERVICE_STATE.FILLED:
				_contact_case = 19
			if _C.PBPacker.check_required(data):
				if limit == -1:
					return _C.PB_ERR.NO_ERRORS
			else:
				return _C.PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return _C.PB_ERR.PARSE_INCOMPLETE
		return result

