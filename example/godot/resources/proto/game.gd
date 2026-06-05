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

const DEFAULT_VALUES_2: Dictionary = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3: Dictionary = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
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

	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value: Variant
	var is_map_field : bool = false
	var option_default : bool = false

	func clear_array() -> void:
		(value as Array).clear()

	func append_array(v: Variant) -> void:
		(value as Array).append(v)

	func as_array() -> Array:
		return value as Array

	func find_map_index(key: Variant) -> int:
		var arr: Array = value as Array
		for i: int in range(arr.size()):
			if arr[i].get_key() == key:
				return i
		return -1

	func set_map_element(index: int, element: Variant) -> void:
		(value as Array)[index] = element


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

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
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

	static func unpack_message(data: Dictionary, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service: PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
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
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data: Dictionary) -> PackedByteArray:
		var DEFAULT_VALUES: Dictionary
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i: Variant in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
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
		var DEFAULT_VALUES: Dictionary
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i: Variant in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result

	@warning_ignore_restore("unsafe_cast", "unsafe_call_argument", "unsafe_method_access", "unsafe_property_access", "untyped_declaration", "inferred_declaration", "return_value_discarded")



############### USER DATA BEGIN ################


const Player = preload("player.gd").Player

class Game:
	extends RefCounted
	func _init() -> void:
		var service: PBServiceField
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __players_default: Array[Player] = []
		__players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __players_default)
		service = PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
		__max_players = PBField.new("max_players", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __max_players
		data[__max_players.tag] = service
		
		__started = PBField.new("started", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __started
		data[__started.tag] = service
		
		__state = PBField.new("state", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __state
		data[__state.tag] = service
		
		__leader = PBField.new("leader", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __leader
		service.func_ref = Callable(self, "new_leader")
		data[__leader.tag] = service
		
		__reward_text = PBField.new("reward_text", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __reward_text
		data[__reward_text.tag] = service
		
		__reward_booster = PBField.new("reward_booster", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __reward_booster
		service.func_ref = Callable(self, "new_reward_booster")
		data[__reward_booster.tag] = service
		
		var __team_default: Array = []
		__team = PBField.new("team", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 9, true, __team_default)
		service = PBServiceField.new()
		service.field = __team
		service.func_ref = Callable(self, "add_empty_team")
		data[__team.tag] = service
		
		__config = PBField.new("config", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __config
		service.func_ref = Callable(self, "new_config")
		data[__config.tag] = service
		
		var __rounds_default: Array[Game.Config] = []
		__rounds = PBField.new("rounds", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 11, true, __rounds_default)
		service = PBServiceField.new()
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

	var __id: PBField
	func has_id() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		data[1].state = PB_SERVICE_STATE.FILLED
		__id.value = value
	
	var __players: PBField
	func get_players() -> Array[Player]:
		return __players.value
	func clear_players() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__players.clear_array()
	func add_players() -> Player:
		var element: Player = Player.new()
		__players.append_array(element)
		return element
	
	var __max_players: PBField
	func has_max_players() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_max_players() -> int:
		return __max_players.value
	func clear_max_players() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__max_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_max_players(value : int) -> void:
		data[3].state = PB_SERVICE_STATE.FILLED
		__max_players.value = value
	
	var __started: PBField
	func has_started() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_started() -> bool:
		return __started.value
	func clear_started() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__started.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_started(value : bool) -> void:
		data[4].state = PB_SERVICE_STATE.FILLED
		__started.value = value
	
	var __state: PBField
	func has_state() -> bool:
		return data[5].state == PB_SERVICE_STATE.FILLED
	func get_state() -> int:
		return __state.value
	func clear_state() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_state(value : int) -> void:
		data[5].state = PB_SERVICE_STATE.FILLED
		__state.value = value
	
	var __leader: PBField
	func has_leader() -> bool:
		return data[6].state == PB_SERVICE_STATE.FILLED
	func get_leader() -> Player:
		return __leader.value
	func clear_leader() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__leader_case = 0
		__leader.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_leader() -> Player:
		data[6].state = PB_SERVICE_STATE.FILLED
		__leader_case = 6
		__leader.value = Player.new()
		return __leader.value
	
	var __reward_text: PBField
	func has_reward_text() -> bool:
		return data[7].state == PB_SERVICE_STATE.FILLED
	func get_reward_text() -> String:
		return __reward_text.value
	func clear_reward_text() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_reward_case = 0
		__reward_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_reward_text(value : String) -> void:
		data[7].state = PB_SERVICE_STATE.FILLED
		_reward_case = 7
		__reward_booster.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__reward_text.value = value
	
	var __reward_booster: PBField
	func has_reward_booster() -> bool:
		return data[8].state == PB_SERVICE_STATE.FILLED
	func get_reward_booster() -> Player:
		return __reward_booster.value
	func clear_reward_booster() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_reward_case = 0
		__reward_booster.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_reward_booster() -> Player:
		__reward_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		data[8].state = PB_SERVICE_STATE.FILLED
		_reward_case = 8
		__reward_booster.value = Player.new()
		return __reward_booster.value
	
	var __team: PBField
	func get_raw_team() -> Variant:
		return __team.value
	func get_team() -> Dictionary:
		return PBPacker.construct_map(__team.as_array())
	func clear_team() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__team.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_team() -> Game.map_type_team:
		var element: Game.map_type_team = Game.map_type_team.new()
		__team.append_array(element)
		return element
	func add_team(a_key: String) -> Player:
		var idx: int = __team.find_map_index(a_key)
		var element: Game.map_type_team = Game.map_type_team.new()
		element.set_key(a_key)
		if idx != -1:
			__team.set_map_element(idx, element)
		else:
			__team.append_array(element)
		return element.new_value()
	
	var __config: PBField
	func has_config() -> bool:
		if __config.value != null:
			return true
		return false
	func get_config() -> Game.Config:
		return __config.value
	func clear_config() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__config.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_config() -> Game.Config:
		__config.value = Game.Config.new()
		return __config.value
	
	var __rounds: PBField
	func get_rounds() -> Array[Game.Config]:
		return __rounds.value
	func clear_rounds() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
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
			var service: PBServiceField
			
			__key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			__key.is_map_field = true
			service = PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = PBField.new("value", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
			__value.is_map_field = true
			service = PBServiceField.new()
			service.field = __value
			service.func_ref = Callable(self, "new_value")
			data[__value.tag] = service
			
		var data: Dictionary = {}
		
		var __key: PBField
		func has_key() -> bool:
			return data[1].state == PB_SERVICE_STATE.FILLED
		func get_key() -> String:
			return __key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_key(value : String) -> void:
			data[1].state = PB_SERVICE_STATE.FILLED
			__key.value = value
		
		var __value: PBField
		func has_value() -> bool:
			if __value.value != null:
				return true
			return false
		func get_value() -> Player:
			return __value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		func new_value() -> Player:
			__value.value = Player.new()
			return __value.value
		
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
		
	class Config:
		extends RefCounted
		func _init() -> void:
			var service: PBServiceField
			
			__friendly_fire = PBField.new("friendly_fire", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
			service = PBServiceField.new()
			service.field = __friendly_fire
			data[__friendly_fire.tag] = service
			
			__time_limit = PBField.new("time_limit", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = __time_limit
			data[__time_limit.tag] = service
			
			__mode = PBField.new("mode", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
			service = PBServiceField.new()
			service.field = __mode
			data[__mode.tag] = service
			
		var data: Dictionary = {}
		
		var __friendly_fire: PBField
		func has_friendly_fire() -> bool:
			return data[1].state == PB_SERVICE_STATE.FILLED
		func get_friendly_fire() -> bool:
			return __friendly_fire.value
		func clear_friendly_fire() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__friendly_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		func set_friendly_fire(value : bool) -> void:
			data[1].state = PB_SERVICE_STATE.FILLED
			__friendly_fire.value = value
		
		var __time_limit: PBField
		func has_time_limit() -> bool:
			return data[2].state == PB_SERVICE_STATE.FILLED
		func get_time_limit() -> float:
			return __time_limit.value
		func clear_time_limit() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__time_limit.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
		func set_time_limit(value : float) -> void:
			data[2].state = PB_SERVICE_STATE.FILLED
			__time_limit.value = value
		
		var __mode: PBField
		func has_mode() -> bool:
			return data[3].state == PB_SERVICE_STATE.FILLED
		func get_mode() -> int:
			return __mode.value
		func clear_mode() -> void:
			data[3].state = PB_SERVICE_STATE.UNFILLED
			__mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
		func set_mode(value : int) -> void:
			data[3].state = PB_SERVICE_STATE.FILLED
			__mode.value = value
		
		enum Mode {
			NORMAL = 0,
			RANKED = 1,
			TOURNAMENT = 2
		}
		
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
			_reward_case = 0
			if data[7].state == PB_SERVICE_STATE.FILLED:
				_reward_case = 7
			if data[8].state == PB_SERVICE_STATE.FILLED:
				_reward_case = 8
			__leader_case = 0
			if data[6].state == PB_SERVICE_STATE.FILLED:
				__leader_case = 6
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result

	
################ USER DATA END #################
