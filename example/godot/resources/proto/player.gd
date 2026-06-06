#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2026, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION: int = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}


enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

@warning_ignore_start("unsafe_cast", "unsafe_call_argument", "unsafe_method_access", "unsafe_property_access", "untyped_declaration", "inferred_declaration", "return_value_discarded")

class PBField:
	extends RefCounted
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value: Variant = null) -> void:
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		if typeof(a_value) == TYPE_ARRAY:
			option_default = (a_value as Array).duplicate(false)
		elif typeof(a_value) == TYPE_DICTIONARY:
			option_default = (a_value as Dictionary).duplicate(false)
		else:
			option_default = a_value
		wire_type = _compute_wire_type(a_type)

	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value: Variant
	var option_default: Variant
	var wire_type: int
	var is_map_field : bool = false
	var _map_index: Dictionary = {}

	static func _compute_wire_type(data_type: int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		return PB_TYPE.LENGTHDEL

	func clear_array() -> void:
		(value as Array).clear()
		_map_index.clear()

	func append_array(v: Variant) -> void:
		var arr: Array = value as Array
		arr.append(v)
		if is_map_field:
			_map_index[v.get_key()] = arr.size() - 1

	func as_array() -> Array:
		return value as Array

	func find_map_index(key: Variant) -> int:
		if is_map_field:
			return _map_index.get(key, -1)
		return -1

	func set_map_element(index: int, element: Variant) -> void:
		var arr: Array = value as Array
		if is_map_field:
			var old: Variant = arr[index]
			_map_index.erase(old.get_key())
		arr[index] = element
		if is_map_field:
			_map_index[element.get_key()] = index

	func rebuild_map_index() -> void:
		if not is_map_field:
			return
		_map_index.clear()
		var arr: Array = value as Array
		for i: int in range(arr.size()):
			_map_index[arr[i].get_key()] = i
class PBTypeTag:
	extends RefCounted
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	extends RefCounted
	var field : PBField
	var func_ref: Callable = Callable()
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value: Variant) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i: int in range(9):
			var b: int = value & 0x7F
			value >>= 7
			if value:
				var _d: bool = varint.append(b | 0x80)
			else:
				var _d: bool = varint.append(b)
				break
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			var _d: bool = varint.append(0x01)
		return varint

	static func pack_bytes(value: Variant, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i: int in range(count):
				var _d: bool = bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int) -> Variant:
		if data_type == PB_DATA_TYPE.FLOAT:
			return bytes.decode_float(index)
		elif data_type == PB_DATA_TYPE.DOUBLE:
			return bytes.decode_double(index)
		elif data_type == PB_DATA_TYPE.FIXED32:
			return bytes.decode_u32(index)
		elif data_type == PB_DATA_TYPE.SFIXED32:
			return bytes.decode_s32(index)
		elif data_type == PB_DATA_TYPE.FIXED64:
			return bytes.decode_u64(index)
		elif data_type == PB_DATA_TYPE.SFIXED64:
			return bytes.decode_s64(index)
		else:
			var value : int = 0
			for i: int in range(count):
				value |= bytes[index + i] << (8 * i)
			return value

	static func unpack_varint(varint_bytes: PackedByteArray) -> int:
		var value : int = 0
		var i: int = varint_bytes.size() - 1
		while i > -1:
			value = (value << 7) | (varint_bytes[i] & 0x7F)
			i -= 1
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var i: int = index
		while i <= index + 10 && i < bytes.size(): # Protobuf varint max size is 10 bytes
			if !(bytes[i] & 0x80):
				return bytes.slice(index, i + 1)
			i += 1
		return [] # Unreachable

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result


	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = field.wire_type
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value: Variant
			if field.rule == PB_RULE.REPEATED:
				for v in (field.value as Array):
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in (field.value as Array):
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in (field.value as Array):
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in (field.value as Array):
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in (field.value as Array):
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in (field.value as Array):
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in (field.value as Array):
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in (field.value as Array):
						var obj: PackedByteArray = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in (field.value as Array):
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof((field.value as Array)[0]) == TYPE_OBJECT:
					for v in (field.value as Array):
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func skip_unknown_field(bytes : PackedByteArray, offset : int, type : int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes : PackedByteArray = isolate_varint(bytes, offset)
			var length : int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref: Callable = Callable()) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count_bytes: PackedByteArray = isolate_varint(bytes, offset)
			if count_bytes.size() > 0:
				offset += count_bytes.size()
				var count: int = unpack_varint(count_bytes)
				if type == PB_TYPE.VARINT:
					var val: Variant
					var counter: int = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size: int
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val: Variant
					var counter: int = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val: Variant = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size: int
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val: Variant
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_bytes: PackedByteArray = isolate_varint(bytes, offset)
				if inner_bytes.size() > 0:
					offset += inner_bytes.size()
					var inner_size: int = unpack_varint(inner_bytes)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref.is_valid():
							var message: RefCounted = message_func_ref.call()
							if inner_size > 0:
								var sub_offset: int = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func _rebuild_map_indexes(data: Dictionary) -> void:
		for svc: Variant in data.values():
			svc.field.rebuild_map_index()

	static func unpack_message(data: Dictionary, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service: PBServiceField = data[tt.tag]
					var type : int = service.field.wire_type
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								_rebuild_map_indexes(data)
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
				else:
					var res : int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
						offset = res
						if offset == limit:
							_rebuild_map_indexes(data)
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break
			else:
				_rebuild_map_indexes(data)
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data: Dictionary) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i: Variant in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& data[i].field.value == data[i].field.option_default:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data: Dictionary) -> bool:
		var keys : Array = data.keys()
		for i: Variant in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values: Array) -> Dictionary:
		var result: Dictionary = {}
		for kv: Variant in key_values:
			result[kv.get_key()] = kv.get_value()
		return result

	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i: int in range(nesting):
			tab += DEBUG_TAB
		return tab + text

	static func value_to_string(value: Variant, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i: int in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result

	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i: int in range(field.value.size()):
					var local_key_value: PBField = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i: int in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result

	static func message_to_string(data: Dictionary, nesting : int = 0) -> String:
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i: Variant in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& data[i].field.value == data[i].field.option_default:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result

	@warning_ignore_restore("unsafe_cast", "unsafe_call_argument", "unsafe_method_access", "unsafe_property_access", "untyped_declaration", "inferred_declaration", "return_value_discarded")



############### USER DATA BEGIN ################


class Player:
	extends RefCounted
	func _init() -> void:
		var service: PBServiceField
		
		__double_val = PBField.new("double_val", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 1, true, 0.0)
		service = PBServiceField.new()
		service.field = __double_val
		data[__double_val.tag] = service
		
		__float_val = PBField.new("float_val", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, 0.0)
		service = PBServiceField.new()
		service.field = __float_val
		data[__float_val.tag] = service
		
		__int32_val = PBField.new("int32_val", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, 0)
		service = PBServiceField.new()
		service.field = __int32_val
		data[__int32_val.tag] = service
		
		__int64_val = PBField.new("int64_val", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 4, true, 0)
		service = PBServiceField.new()
		service.field = __int64_val
		data[__int64_val.tag] = service
		
		__uint32_val = PBField.new("uint32_val", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 5, true, 0)
		service = PBServiceField.new()
		service.field = __uint32_val
		data[__uint32_val.tag] = service
		
		__uint64_val = PBField.new("uint64_val", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 6, true, 0)
		service = PBServiceField.new()
		service.field = __uint64_val
		data[__uint64_val.tag] = service
		
		__sint32_val = PBField.new("sint32_val", PB_DATA_TYPE.SINT32, PB_RULE.OPTIONAL, 7, true, 0)
		service = PBServiceField.new()
		service.field = __sint32_val
		data[__sint32_val.tag] = service
		
		__sint64_val = PBField.new("sint64_val", PB_DATA_TYPE.SINT64, PB_RULE.OPTIONAL, 8, true, 0)
		service = PBServiceField.new()
		service.field = __sint64_val
		data[__sint64_val.tag] = service
		
		__fixed32_val = PBField.new("fixed32_val", PB_DATA_TYPE.FIXED32, PB_RULE.OPTIONAL, 9, true, 0)
		service = PBServiceField.new()
		service.field = __fixed32_val
		data[__fixed32_val.tag] = service
		
		__fixed64_val = PBField.new("fixed64_val", PB_DATA_TYPE.FIXED64, PB_RULE.OPTIONAL, 10, true, 0)
		service = PBServiceField.new()
		service.field = __fixed64_val
		data[__fixed64_val.tag] = service
		
		__sfixed32_val = PBField.new("sfixed32_val", PB_DATA_TYPE.SFIXED32, PB_RULE.OPTIONAL, 11, true, 0)
		service = PBServiceField.new()
		service.field = __sfixed32_val
		data[__sfixed32_val.tag] = service
		
		__sfixed64_val = PBField.new("sfixed64_val", PB_DATA_TYPE.SFIXED64, PB_RULE.OPTIONAL, 12, true, 0)
		service = PBServiceField.new()
		service.field = __sfixed64_val
		data[__sfixed64_val.tag] = service
		
		__bool_val = PBField.new("bool_val", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 13, true, false)
		service = PBServiceField.new()
		service.field = __bool_val
		data[__bool_val.tag] = service
		
		__string_val = PBField.new("string_val", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 14, true, "")
		service = PBServiceField.new()
		service.field = __string_val
		data[__string_val.tag] = service
		
		__bytes_val = PBField.new("bytes_val", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 15, true, [])
		service = PBServiceField.new()
		service.field = __bytes_val
		data[__bytes_val.tag] = service
		
		__class = PBField.new("class", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 16, true, 0)
		service = PBServiceField.new()
		service.field = __class
		data[__class.tag] = service
		
		var __items_default: Array[String] = []
		__items = PBField.new("items", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 17, true, __items_default)
		service = PBServiceField.new()
		service.field = __items
		data[__items.tag] = service
		
		__email = PBField.new("email", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 18, true, "")
		service = PBServiceField.new()
		service.field = __email
		data[__email.tag] = service
		
		__phone = PBField.new("phone", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 19, true, 0)
		service = PBServiceField.new()
		service.field = __phone
		data[__phone.tag] = service
		
		__stats = PBField.new("stats", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 20, true, null)
		service = PBServiceField.new()
		service.field = __stats
		service.func_ref = Callable(self, "new_stats")
		data[__stats.tag] = service
		
		var __history_default: Array[Player.Stats] = []
		__history = PBField.new("history", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 21, true, __history_default)
		service = PBServiceField.new()
		service.field = __history
		service.func_ref = Callable(self, "add_history")
		data[__history.tag] = service
		
		var __metadata_default: Array = []
		__metadata = PBField.new("metadata", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 22, true, __metadata_default)
		__metadata.is_map_field = true
		service = PBServiceField.new()
		service.field = __metadata
		service.func_ref = Callable(self, "add_empty_metadata")
		data[__metadata.tag] = service
		
		var __labels_default: Array = []
		__labels = PBField.new("labels", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 23, true, __labels_default)
		__labels.is_map_field = true
		service = PBServiceField.new()
		service.field = __labels
		service.func_ref = Callable(self, "add_empty_labels")
		data[__labels.tag] = service
		
		var __skills_default: Array = []
		__skills = PBField.new("skills", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 24, true, __skills_default)
		__skills.is_map_field = true
		service = PBServiceField.new()
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

	var __double_val: PBField
	func has_double_val() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_double_val() -> float:
		return __double_val.value
	func clear_double_val() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__double_val.value = 0.0
	func set_double_val(value : float) -> void:
		data[1].state = PB_SERVICE_STATE.FILLED
		__double_val.value = value
	
	var __float_val: PBField
	func has_float_val() -> bool:
		return data[2].state == PB_SERVICE_STATE.FILLED
	func get_float_val() -> float:
		return __float_val.value
	func clear_float_val() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__float_val.value = 0.0
	func set_float_val(value : float) -> void:
		data[2].state = PB_SERVICE_STATE.FILLED
		__float_val.value = value
	
	var __int32_val: PBField
	func has_int32_val() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_int32_val() -> int:
		return __int32_val.value
	func clear_int32_val() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__int32_val.value = 0
	func set_int32_val(value : int) -> void:
		data[3].state = PB_SERVICE_STATE.FILLED
		__int32_val.value = value
	
	var __int64_val: PBField
	func has_int64_val() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_int64_val() -> int:
		return __int64_val.value
	func clear_int64_val() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__int64_val.value = 0
	func set_int64_val(value : int) -> void:
		data[4].state = PB_SERVICE_STATE.FILLED
		__int64_val.value = value
	
	var __uint32_val: PBField
	func has_uint32_val() -> bool:
		return data[5].state == PB_SERVICE_STATE.FILLED
	func get_uint32_val() -> int:
		return __uint32_val.value
	func clear_uint32_val() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__uint32_val.value = 0
	func set_uint32_val(value : int) -> void:
		data[5].state = PB_SERVICE_STATE.FILLED
		__uint32_val.value = value
	
	var __uint64_val: PBField
	func has_uint64_val() -> bool:
		return data[6].state == PB_SERVICE_STATE.FILLED
	func get_uint64_val() -> int:
		return __uint64_val.value
	func clear_uint64_val() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__uint64_val.value = 0
	func set_uint64_val(value : int) -> void:
		data[6].state = PB_SERVICE_STATE.FILLED
		__uint64_val.value = value
	
	var __sint32_val: PBField
	func has_sint32_val() -> bool:
		return data[7].state == PB_SERVICE_STATE.FILLED
	func get_sint32_val() -> int:
		return __sint32_val.value
	func clear_sint32_val() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__sint32_val.value = 0
	func set_sint32_val(value : int) -> void:
		data[7].state = PB_SERVICE_STATE.FILLED
		__sint32_val.value = value
	
	var __sint64_val: PBField
	func has_sint64_val() -> bool:
		return data[8].state == PB_SERVICE_STATE.FILLED
	func get_sint64_val() -> int:
		return __sint64_val.value
	func clear_sint64_val() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__sint64_val.value = 0
	func set_sint64_val(value : int) -> void:
		data[8].state = PB_SERVICE_STATE.FILLED
		__sint64_val.value = value
	
	var __fixed32_val: PBField
	func has_fixed32_val() -> bool:
		return data[9].state == PB_SERVICE_STATE.FILLED
	func get_fixed32_val() -> int:
		return __fixed32_val.value
	func clear_fixed32_val() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__fixed32_val.value = 0
	func set_fixed32_val(value : int) -> void:
		data[9].state = PB_SERVICE_STATE.FILLED
		__fixed32_val.value = value
	
	var __fixed64_val: PBField
	func has_fixed64_val() -> bool:
		return data[10].state == PB_SERVICE_STATE.FILLED
	func get_fixed64_val() -> int:
		return __fixed64_val.value
	func clear_fixed64_val() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__fixed64_val.value = 0
	func set_fixed64_val(value : int) -> void:
		data[10].state = PB_SERVICE_STATE.FILLED
		__fixed64_val.value = value
	
	var __sfixed32_val: PBField
	func has_sfixed32_val() -> bool:
		return data[11].state == PB_SERVICE_STATE.FILLED
	func get_sfixed32_val() -> int:
		return __sfixed32_val.value
	func clear_sfixed32_val() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__sfixed32_val.value = 0
	func set_sfixed32_val(value : int) -> void:
		data[11].state = PB_SERVICE_STATE.FILLED
		__sfixed32_val.value = value
	
	var __sfixed64_val: PBField
	func has_sfixed64_val() -> bool:
		return data[12].state == PB_SERVICE_STATE.FILLED
	func get_sfixed64_val() -> int:
		return __sfixed64_val.value
	func clear_sfixed64_val() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__sfixed64_val.value = 0
	func set_sfixed64_val(value : int) -> void:
		data[12].state = PB_SERVICE_STATE.FILLED
		__sfixed64_val.value = value
	
	var __bool_val: PBField
	func has_bool_val() -> bool:
		return data[13].state == PB_SERVICE_STATE.FILLED
	func get_bool_val() -> bool:
		return __bool_val.value
	func clear_bool_val() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__bool_val.value = false
	func set_bool_val(value : bool) -> void:
		data[13].state = PB_SERVICE_STATE.FILLED
		__bool_val.value = value
	
	var __string_val: PBField
	func has_string_val() -> bool:
		return data[14].state == PB_SERVICE_STATE.FILLED
	func get_string_val() -> String:
		return __string_val.value
	func clear_string_val() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__string_val.value = ""
	func set_string_val(value : String) -> void:
		data[14].state = PB_SERVICE_STATE.FILLED
		__string_val.value = value
	
	var __bytes_val: PBField
	func has_bytes_val() -> bool:
		return data[15].state == PB_SERVICE_STATE.FILLED
	func get_bytes_val() -> PackedByteArray:
		return __bytes_val.value
	func clear_bytes_val() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__bytes_val.value = []
	func set_bytes_val(value : PackedByteArray) -> void:
		data[15].state = PB_SERVICE_STATE.FILLED
		__bytes_val.value = value
	
	var __class: PBField
	func has_class() -> bool:
		return data[16].state == PB_SERVICE_STATE.FILLED
	func get_class_() -> int:
		return __class.value
	func clear_class() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__class.value = 0
	func set_class(value : int) -> void:
		data[16].state = PB_SERVICE_STATE.FILLED
		__class.value = value
	
	var __items: PBField
	func get_items() -> Array[String]:
		return __items.value
	func clear_items() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__items.clear_array()
	func add_items(value : String) -> void:
		__items.append_array(value)
	
	var __email: PBField
	func has_email() -> bool:
		return data[18].state == PB_SERVICE_STATE.FILLED
	func get_email() -> String:
		return __email.value
	func clear_email() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_contact_case = 0
		__email.value = ""
	func set_email(value : String) -> void:
		data[18].state = PB_SERVICE_STATE.FILLED
		_contact_case = 18
		__phone.value = 0
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__email.value = value
	
	var __phone: PBField
	func has_phone() -> bool:
		return data[19].state == PB_SERVICE_STATE.FILLED
	func get_phone() -> int:
		return __phone.value
	func clear_phone() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_contact_case = 0
		__phone.value = 0
	func set_phone(value : int) -> void:
		__email.value = ""
		data[18].state = PB_SERVICE_STATE.UNFILLED
		data[19].state = PB_SERVICE_STATE.FILLED
		_contact_case = 19
		__phone.value = value
	
	var __stats: PBField
	func has_stats() -> bool:
		if __stats.value != null:
			return true
		return false
	func get_stats() -> Player.Stats:
		return __stats.value
	func clear_stats() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__stats.value = null
	func new_stats() -> Player.Stats:
		__stats.value = Player.Stats.new()
		return __stats.value
	
	var __history: PBField
	func get_history() -> Array[Player.Stats]:
		return __history.value
	func clear_history() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__history.clear_array()
	func add_history() -> Player.Stats:
		var element: Player.Stats = Player.Stats.new()
		__history.append_array(element)
		return element
	
	var __metadata: PBField
	var __metadata_cached: Dictionary = {}
	var __metadata_cache_valid: bool = false
	func get_raw_metadata() -> Variant:
		return __metadata.value
	func get_metadata() -> Dictionary:
		if not __metadata_cache_valid:
			__metadata_cached = PBPacker.construct_map(__metadata.as_array())
			__metadata_cache_valid = true
		return __metadata_cached
	func clear_metadata() -> void:
		__metadata_cache_valid = false
		data[22].state = PB_SERVICE_STATE.UNFILLED
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
	
	var __labels: PBField
	var __labels_cached: Dictionary = {}
	var __labels_cache_valid: bool = false
	func get_raw_labels() -> Variant:
		return __labels.value
	func get_labels() -> Dictionary:
		if not __labels_cache_valid:
			__labels_cached = PBPacker.construct_map(__labels.as_array())
			__labels_cache_valid = true
		return __labels_cached
	func clear_labels() -> void:
		__labels_cache_valid = false
		data[23].state = PB_SERVICE_STATE.UNFILLED
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
	
	var __skills: PBField
	var __skills_cached: Dictionary = {}
	var __skills_cache_valid: bool = false
	func get_raw_skills() -> Variant:
		return __skills.value
	func get_skills() -> Dictionary:
		if not __skills_cache_valid:
			__skills_cached = PBPacker.construct_map(__skills.as_array())
			__skills_cache_valid = true
		return __skills_cached
	func clear_skills() -> void:
		__skills_cache_valid = false
		data[24].state = PB_SERVICE_STATE.UNFILLED
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
			var service: PBServiceField
			
			__strength = PBField.new("strength", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, 0)
			service = PBServiceField.new()
			service.field = __strength
			data[__strength.tag] = service
			
			__agility = PBField.new("agility", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, 0)
			service = PBServiceField.new()
			service.field = __agility
			data[__agility.tag] = service
			
			__intelligence = PBField.new("intelligence", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, 0)
			service = PBServiceField.new()
			service.field = __intelligence
			data[__intelligence.tag] = service
			
		var data: Dictionary = {}
		
		var __strength: PBField
		func has_strength() -> bool:
			return data[1].state == PB_SERVICE_STATE.FILLED
		func get_strength() -> int:
			return __strength.value
		func clear_strength() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__strength.value = 0
		func set_strength(value : int) -> void:
			data[1].state = PB_SERVICE_STATE.FILLED
			__strength.value = value
		
		var __agility: PBField
		func has_agility() -> bool:
			return data[2].state == PB_SERVICE_STATE.FILLED
		func get_agility() -> int:
			return __agility.value
		func clear_agility() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__agility.value = 0
		func set_agility(value : int) -> void:
			data[2].state = PB_SERVICE_STATE.FILLED
			__agility.value = value
		
		var __intelligence: PBField
		func has_intelligence() -> bool:
			return data[3].state == PB_SERVICE_STATE.FILLED
		func get_intelligence() -> int:
			return __intelligence.value
		func clear_intelligence() -> void:
			data[3].state = PB_SERVICE_STATE.UNFILLED
			__intelligence.value = 0
		func set_intelligence(value : int) -> void:
			data[3].state = PB_SERVICE_STATE.FILLED
			__intelligence.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit: int = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result: int = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_metadata:
		extends RefCounted
		func _init() -> void:
			var service: PBServiceField
			
			__key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, "")
			service = PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, "")
			service = PBServiceField.new()
			service.field = __value
			data[__value.tag] = service
			
		var data: Dictionary = {}
		
		var __key: PBField
		func has_key() -> bool:
			return data[1].state == PB_SERVICE_STATE.FILLED
		func get_key() -> String:
			return __key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__key.value = ""
		func set_key(value : String) -> void:
			data[1].state = PB_SERVICE_STATE.FILLED
			__key.value = value
		
		var __value: PBField
		func has_value() -> bool:
			return data[2].state == PB_SERVICE_STATE.FILLED
		func get_value() -> String:
			return __value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__value.value = ""
		func set_value(value : String) -> void:
			data[2].state = PB_SERVICE_STATE.FILLED
			__value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit: int = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result: int = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_labels:
		extends RefCounted
		func _init() -> void:
			var service: PBServiceField
			
			__key = PBField.new("key", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, 0)
			service = PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, "")
			service = PBServiceField.new()
			service.field = __value
			data[__value.tag] = service
			
		var data: Dictionary = {}
		
		var __key: PBField
		func has_key() -> bool:
			return data[1].state == PB_SERVICE_STATE.FILLED
		func get_key() -> int:
			return __key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__key.value = 0
		func set_key(value : int) -> void:
			data[1].state = PB_SERVICE_STATE.FILLED
			__key.value = value
		
		var __value: PBField
		func has_value() -> bool:
			return data[2].state == PB_SERVICE_STATE.FILLED
		func get_value() -> String:
			return __value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__value.value = ""
		func set_value(value : String) -> void:
			data[2].state = PB_SERVICE_STATE.FILLED
			__value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit: int = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result: int = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_skills:
		extends RefCounted
		func _init() -> void:
			var service: PBServiceField
			
			__key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, "")
			service = PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = PBField.new("value", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 2, true, 0)
			service = PBServiceField.new()
			service.field = __value
			data[__value.tag] = service
			
		var data: Dictionary = {}
		
		var __key: PBField
		func has_key() -> bool:
			return data[1].state == PB_SERVICE_STATE.FILLED
		func get_key() -> String:
			return __key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__key.value = ""
		func set_key(value : String) -> void:
			data[1].state = PB_SERVICE_STATE.FILLED
			__key.value = value
		
		var __value: PBField
		func has_value() -> bool:
			return data[2].state == PB_SERVICE_STATE.FILLED
		func get_value() -> int:
			return __value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__value.value = 0
		func set_value(value : int) -> void:
			data[2].state = PB_SERVICE_STATE.FILLED
			__value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit: int = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result: int = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit: int = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result: int = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			_contact_case = 0
			if data[18].state == PB_SERVICE_STATE.FILLED:
				_contact_case = 18
			if data[19].state == PB_SERVICE_STATE.FILLED:
				_contact_case = 19
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result

	
################ USER DATA END #################
