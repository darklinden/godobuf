"""GDScript code generator from FileDescriptorProto."""

from google.protobuf.descriptor_pb2 import (
    FieldDescriptorProto,
    FileDescriptorProto,
)

ONE_OF_CASE_FUNCTION_SUFFIX = "_case"
ONE_OF_CASE_ENUM_FIELD_SUFFIX = "Case"
ONE_OF_CASE_INNER_FIELD_SUFFIX = "_case"
ONE_OF_CASE_DEFAULT_VALUE = 0

# FieldDescriptorProto.TYPE_* → PB_DATA_TYPE string
_TYPE_TO_PB: dict[int, str] = {
    FieldDescriptorProto.TYPE_DOUBLE: "PB_DATA_TYPE.DOUBLE",
    FieldDescriptorProto.TYPE_FLOAT: "PB_DATA_TYPE.FLOAT",
    FieldDescriptorProto.TYPE_INT32: "PB_DATA_TYPE.INT32",
    FieldDescriptorProto.TYPE_SINT32: "PB_DATA_TYPE.SINT32",
    FieldDescriptorProto.TYPE_UINT32: "PB_DATA_TYPE.UINT32",
    FieldDescriptorProto.TYPE_INT64: "PB_DATA_TYPE.INT64",
    FieldDescriptorProto.TYPE_SINT64: "PB_DATA_TYPE.SINT64",
    FieldDescriptorProto.TYPE_UINT64: "PB_DATA_TYPE.UINT64",
    FieldDescriptorProto.TYPE_BOOL: "PB_DATA_TYPE.BOOL",
    FieldDescriptorProto.TYPE_ENUM: "PB_DATA_TYPE.ENUM",
    FieldDescriptorProto.TYPE_FIXED32: "PB_DATA_TYPE.FIXED32",
    FieldDescriptorProto.TYPE_SFIXED32: "PB_DATA_TYPE.SFIXED32",
    FieldDescriptorProto.TYPE_FIXED64: "PB_DATA_TYPE.FIXED64",
    FieldDescriptorProto.TYPE_SFIXED64: "PB_DATA_TYPE.SFIXED64",
    FieldDescriptorProto.TYPE_STRING: "PB_DATA_TYPE.STRING",
    FieldDescriptorProto.TYPE_BYTES: "PB_DATA_TYPE.BYTES",
    FieldDescriptorProto.TYPE_MESSAGE: "PB_DATA_TYPE.MESSAGE",
}

# FieldDescriptorProto.TYPE_* → GDScript type string
_TYPE_TO_GD: dict[int, str] = {
    FieldDescriptorProto.TYPE_DOUBLE: "float",
    FieldDescriptorProto.TYPE_FLOAT: "float",
    FieldDescriptorProto.TYPE_INT32: "int",
    FieldDescriptorProto.TYPE_SINT32: "int",
    FieldDescriptorProto.TYPE_UINT32: "int",
    FieldDescriptorProto.TYPE_INT64: "int",
    FieldDescriptorProto.TYPE_SINT64: "int",
    FieldDescriptorProto.TYPE_UINT64: "int",
    FieldDescriptorProto.TYPE_BOOL: "bool",
    FieldDescriptorProto.TYPE_ENUM: "int",
    FieldDescriptorProto.TYPE_FIXED32: "int",
    FieldDescriptorProto.TYPE_SFIXED32: "int",
    FieldDescriptorProto.TYPE_FIXED64: "int",
    FieldDescriptorProto.TYPE_SFIXED64: "int",
    FieldDescriptorProto.TYPE_STRING: "String",
    FieldDescriptorProto.TYPE_BYTES: "PackedByteArray",
}


class TypeInfo:
    __slots__ = ("full_name", "gdscript_name", "kind", "source_file")
    def __init__(self, full_name: str, gdscript_name: str, kind: str, source_file: str = ""):
        self.full_name = full_name
        self.gdscript_name = gdscript_name
        self.kind = kind  # "message", "enum", "map"
        self.source_file = source_file  # proto file name, e.g. "player.proto"


def _tab(text: str, n: int) -> str:
    return "\t" * n + text


def _default_dict(proto_version: int) -> str:
    return "DEFAULT_VALUES_2" if proto_version == 2 else "DEFAULT_VALUES_3"


def _pb_type(field) -> str:
    return _TYPE_TO_PB.get(field.type, "PB_DATA_TYPE.INT32")


def _gd_type(field) -> str:
    return _TYPE_TO_GD.get(field.type, "")


def _pb_rule(field) -> str:
    if field.label == FieldDescriptorProto.LABEL_REQUIRED:
        return "PB_RULE.REQUIRED"
    elif field.label == FieldDescriptorProto.LABEL_REPEATED:
        return "PB_RULE.REPEATED"
    return "PB_RULE.OPTIONAL"


def _getter_suffix(name: str) -> str:
    return "_" if name in ("class", "script") else ""


def _to_pascal(s: str) -> str:
    return "".join(p.capitalize() for p in s.split("_"))


def _to_snake_upper(s: str) -> str:
    result = []
    for ch in s:
        if ch.isupper() and result:
            result.append("_")
        result.append(ch.lower())
    return "".join(result).upper()


def _enum_name_strip(enum_values) -> list[str]:
    """Strip common enum value prefix if all values share it."""
    if not enum_values:
        return []
    # Find the prefix: common prefix ending in _
    prefix = None
    for v in enum_values:
        name = v.name
        # Find last _ that's not at the end
        idx = name.rfind("_")
        if idx <= 0:
            return [v.name for v in enum_values]
        candidate = name[:idx + 1]
        if prefix is None:
            prefix = candidate
        elif candidate != prefix:
            return [v.name for v in enum_values]

    if prefix is None:
        return [v.name for v in enum_values]
    # Only strip if ALL values start with prefix and are not just the prefix
    for v in enum_values:
        if not (v.name.startswith(prefix) and v.name != prefix[:-1]):
            return [v.name for v in enum_values]
    return [v.name[len(prefix):] for v in enum_values]


def build_type_map(file_descs: list, prefix: str) -> dict[str, TypeInfo]:
    """Build full proto name → TypeInfo mapping from all file descriptors."""
    result: dict[str, TypeInfo] = {}

    def _proto_to_gd(proto_file: str) -> str:
        if proto_file.endswith(".proto"):
            return proto_file[:-6] + ".gd"
        return proto_file + ".gd"

    def _qual(package: str, parent: str, name: str) -> str:
        if parent:
            return f".{package}.{parent}.{name}"
        return f".{package}.{name}"

    def _gd_name(proto_parent: str, name: str, kind: str) -> str:
        parts = []
        if proto_parent:
            for p in proto_parent.split("."):
                parts.append(prefix + p)
        if kind == "message":
            parts.append(prefix + name)
        else:
            parts.append(name)
        return ".".join(parts)

    def _walk_message(msg, package: str, proto_parent: str, source: str):
        if msg.options.map_entry:
            full = _qual(package, proto_parent, msg.name).lstrip(".")
            gd = _gd_name(proto_parent, msg.name, "message")
            result[full] = TypeInfo(full, gd, "map", source)
            return
        full = _qual(package, proto_parent, msg.name).lstrip(".")
        gd = _gd_name(proto_parent, msg.name, "message")
        result[full] = TypeInfo(full, gd, "message", source)

        for enum in msg.enum_type:
            full_e = _qual(package, proto_parent + "." + msg.name if proto_parent else msg.name, enum.name).lstrip(".")
            gd_e = _gd_name(proto_parent + "." + msg.name if proto_parent else msg.name, enum.name, "enum")
            result[full_e] = TypeInfo(full_e, gd_e, "enum", source)

        for nested in msg.nested_type:
            new_parent = proto_parent + "." + msg.name if proto_parent else msg.name
            _walk_message(nested, package, new_parent, source)

    for fd in file_descs:
        source_gd = _proto_to_gd(fd.name)
        for enum in fd.enum_type:
            full = _qual(fd.package, "", enum.name).lstrip(".")
            gd = _gd_name("", enum.name, "enum")
            result[full] = TypeInfo(full, gd, "enum", source_gd)
        for msg in fd.message_type:
            _walk_message(msg, fd.package, "", source_gd)

    return result


class Generator:
    """Generates GDScript code from a FileDescriptorProto."""

    def __init__(self, file_desc: FileDescriptorProto,
                 type_map: dict[str, TypeInfo],
                 proto_version: int,
                 prefix: str = "",
                 should_prefix_enums: bool = False):
        self.fd = file_desc
        self.type_map = type_map
        self.proto_version = proto_version
        self.prefix = prefix
        self.should_prefix_enums = should_prefix_enums
        self._source_lines: dict[tuple, int] = self._build_source_lines()

    def _build_source_lines(self) -> dict[tuple, int]:
        """Build dict mapping path tuple -> source line number (0-indexed)."""
        result: dict[tuple, int] = {}
        if not self.fd.HasField('source_code_info'):
            return result
        for loc in self.fd.source_code_info.location:
            result[tuple(loc.path)] = loc.span[0]
        return result

    def _get_line(self, path: tuple) -> int:
        return self._source_lines.get(path, 0)

    def _proto_file_to_gd(self) -> str:
        proto_name = self.fd.name
        if proto_name.endswith(".proto"):
            return proto_name[:-6] + ".gd"
        return proto_name + ".gd"

    def _collect_external_refs(self, msg, package: str, proto_parent: str,
                               refs: dict[str, str]) -> None:
        """Collect external type references that need preload constants."""
        cur_proto_parent = proto_parent + "." + msg.name if proto_parent else msg.name
        current_gd = self._proto_file_to_gd()

        for field in msg.field:
            if field.type not in (FieldDescriptorProto.TYPE_MESSAGE,
                                  FieldDescriptorProto.TYPE_ENUM):
                continue
            type_name = field.type_name.lstrip(".")
            info = self.type_map.get(type_name)
            if info is None:
                continue
            # Check if this type comes from a different file
            if info.source_file and info.source_file != current_gd:
                # Get the top-level GDScript class name (first part before dot)
                top_class = info.gdscript_name.split(".")[0]
                if top_class not in refs:
                    refs[top_class] = info.source_file

        # Recurse into nested messages
        for nested in msg.nested_type:
            if nested.options.map_entry:
                continue
            self._collect_external_refs(nested, package, cur_proto_parent, refs)

    def generate(self) -> str:
        """Generate the user-data section (classes + enums) for this file."""
        parts = []

        # Collect external file preloads needed by all top-level messages
        external_preloads: dict[str, str] = {}
        for msg in self.fd.message_type:
            if msg.options.map_entry:
                continue
            self._collect_external_refs(msg, self.fd.package, "", external_preloads)

        # File-level preloads for external types referenced by messages
        for gd_class, gd_file in sorted(external_preloads.items()):
            parts.append(f'const {gd_class} = preload("{gd_file}").{gd_class}\n')
        if external_preloads:
            parts.append("\n")

        # Top-level enums
        for enum in self.fd.enum_type:
            parts.append(self._gen_enum(enum, 0))
            parts.append("\n")

        # Top-level messages
        for i, msg in enumerate(self.fd.message_type):
            if msg.options.map_entry:
                continue
            parts.append(self._gen_message(msg, 0, self.fd.package, "",
                                           (4, i)))
            parts.append("\n")

        return "".join(parts)

    def _resolve(self, type_name: str) -> str:
        """Convert proto full type name to GDScript class reference."""
        key = type_name.lstrip(".")
        info = self.type_map.get(key)
        if info is None:
            # Strip package prefix as fallback
            return type_name.lstrip(".").split(".", 1)[-1] if "." in type_name.lstrip(".") else type_name.lstrip(".")
        return info.gdscript_name

    def _packed(self) -> str:
        return "true" if self.proto_version == 3 else "false"

    def _gen_enum(self, enum, nesting: int) -> str:
        name = enum.name
        text = ""
        if self.should_prefix_enums:
            text += _tab(f"enum {self.prefix}{name} {{\n", nesting)
        else:
            text += _tab(f"enum {name} {{\n", nesting)
        nesting += 1

        stripped_names = _enum_name_strip(enum.value)

        for i, v in enumerate(enum.value):
            val_name = stripped_names[i]
            line = f"{val_name} = {v.number}"
            if i < len(enum.value) - 1:
                line += ","
            text += _tab(line + "\n", nesting)

        nesting -= 1
        text += _tab("}\n", nesting)
        return text

    def _gen_message(self, msg, nesting: int, package: str,
                     proto_parent: str, msg_path: tuple = ()) -> str:
        if msg.options.map_entry:
            return ""  # handled via gen_map_class from parent

        name = msg.name
        gd_name = self.prefix + name
        text = ""

        # Build class path parts for nested message type references
        cur_proto_parent = proto_parent + "." + name if proto_parent else name

        text += _tab(f"class {gd_name}:\n", nesting)
        nesting += 1
        text += _tab("extends RefCounted\n", nesting)
        text += _tab("func _init() -> void:\n", nesting)
        nesting += 1
        text += _tab("var service: PBServiceField\n", nesting)
        text += _tab("\n", nesting)

        # Map entry → field name and field index lookup
        map_entry_fields: dict[str, str] = {}
        field_index_map: dict[str, int] = {}
        for fi, field in enumerate(msg.field):
            if field.type == FieldDescriptorProto.TYPE_MESSAGE and field.label == FieldDescriptorProto.LABEL_REPEATED:
                entry_name = field.type_name.lstrip(".")
                map_entry_fields[entry_name] = field.name
                field_index_map[entry_name] = fi

        # Field constructors
        oneof_map: dict[int, list] = {}
        for field in msg.field:
            if field.HasField("oneof_index"):
                oneof_map.setdefault(field.oneof_index, []).append(field)

            text += self._gen_field_ctor(field, nesting, package, cur_proto_parent)

        nesting -= 1
        text += _tab("var data: Dictionary = {}\n", nesting)
        text += _tab("\n", nesting)

        # Oneof defs
        for oi, oneof in enumerate(msg.oneof_decl):
            ofields = oneof_map.get(oi, [])
            if ofields:
                text += self._gen_oneof_defs(oneof, ofields, nesting)
                text += "\n"

        # Field methods
        field_text = ""
        for field in msg.field:
            in_oneof = field.HasField("oneof_index")
            siblings = oneof_map.get(field.oneof_index, []) if in_oneof else []
            oname = msg.oneof_decl[field.oneof_index].name if in_oneof else ""
            field_text += self._gen_field(field, in_oneof, siblings, nesting,
                                           package, cur_proto_parent, oname)
            field_text += _tab("\n", nesting)

        text += field_text

        # Oneof getters (no blank line after — next section follows directly)
        for oneof in msg.oneof_decl:
            text += self._gen_oneof_getter(oneof, nesting)

        # Build sorted list of nested declarations (enums + messages)
        nested_items: list[tuple[int, str, object]] = []
        for ei, enum in enumerate(msg.enum_type):
            line = self._get_line(msg_path + (5, ei))
            nested_items.append((line, 'enum', enum))
        for ni, nested_msg in enumerate(msg.nested_type):
            if nested_msg.options.map_entry:
                entry_name = f".{package}.{cur_proto_parent}.{nested_msg.name}"
                fi = field_index_map.get(entry_name.lstrip("."), -1)
                if fi == -1:
                    for k, v in map_entry_fields.items():
                        if k.endswith("." + nested_msg.name):
                            fi = field_index_map.get(k, -1)
                            break
                line = self._get_line(msg_path + (2, fi)) if fi >= 0 else 0
                nested_items.append((line, 'map', (nested_msg, fi)))
            else:
                line = self._get_line(msg_path + (3, ni))
                nested_items.append((line, 'message', (nested_msg, ni)))

        nested_items.sort(key=lambda x: x[0])

        # Generate nested declarations in source order
        nested_count = 0
        for _, kind, item in nested_items:
            if kind == 'enum':
                text += self._gen_enum(item, nesting)
                text += _tab("\n", nesting)
                nested_count += 1
            elif kind == 'map':
                nested_msg, fi = item
                if fi >= 0:
                    entry_name_full = f".{package}.{cur_proto_parent}.{nested_msg.name}"
                    field_name = map_entry_fields.get(entry_name_full.lstrip("."))
                    if field_name is None:
                        for k, v in map_entry_fields.items():
                            if k.endswith("." + nested_msg.name):
                                field_name = v
                                break
                    if field_name:
                        text += self._gen_map_class(nested_msg, field_name, nesting,
                                                     package, cur_proto_parent)
                        text += self.gen_class_services(nesting + 1)
                        text += _tab("\n", nesting + 1)
                        nested_count += 1
            elif kind == 'message':
                nested_msg, ni = item
                text += self._gen_message(nested_msg, nesting, package,
                                          cur_proto_parent, msg_path + (3, ni))
                text += _tab("\n", nesting + 1)
                nested_count += 1

        # Replace trailing gap after last nested item with parent-level gap
        # (from class body level \t\t\n to parent body level \t\n)
        if nested_count > 0 and text.endswith(_tab("\n", nesting + 1)):
            text = text[:-len(_tab("\n", nesting + 1))] + _tab("\n", nesting)

        # Class services for this message
        text += self.gen_class_services(nesting, msg)

        nesting -= 1
        return text

    def _gen_field_ctor(self, field, nesting: int, package: str,
                        proto_parent: str, is_map_entry: bool = False) -> str:
        fname = f"__{field.name}"
        text = ""

        is_map = self._is_map_field(field)
        pb_type_str = "PB_DATA_TYPE.MAP" if is_map else _pb_type(field)
        pb = f'{fname} = PBField.new("{field.name}", {pb_type_str}, {_pb_rule(field)}, {field.number}, {self._packed()}'

        default_var = f"{fname}_default"
        is_repeated = field.label == FieldDescriptorProto.LABEL_REPEATED
        is_msg = field.type == FieldDescriptorProto.TYPE_MESSAGE

        if is_repeated:
            if is_map:
                text += _tab(f"var {default_var}: Array = []\n", nesting)
            elif is_msg:
                type_name = self._resolve(field.type_name)
                text += _tab(f"var {default_var}: Array[{type_name}] = []\n", nesting)
            else:
                gd_type = _gd_type(field)
                if gd_type:
                    text += _tab(f"var {default_var}: Array[{gd_type}] = []\n", nesting)
                else:
                    text += _tab(f"var {default_var}: Array = []\n", nesting)
            pb += f", {default_var}"
        else:
            pb += f", {_default_dict(self.proto_version)}[{pb_type_str}]"

        pb += ")\n"

        text += _tab(pb, nesting)
        if is_map_entry:
            text += _tab(f"{fname}.is_map_field = true\n", nesting)
        text += _tab("service = PBServiceField.new()\n", nesting)
        text += _tab("service.field = " + fname + "\n", nesting)

        if is_msg and not is_map:
            if is_repeated:
                text += _tab(f'service.func_ref = Callable(self, "add_{field.name}")\n', nesting)
            else:
                text += _tab(f'service.func_ref = Callable(self, "new_{field.name}")\n', nesting)
        elif is_map:
            text += _tab(f'service.func_ref = Callable(self, "add_empty_{field.name}")\n', nesting)

        text += _tab(f"data[{fname}.tag] = service\n", nesting)
        text += _tab("\n", nesting)
        return text

    def _is_map_field(self, field) -> bool:
        if field.label != FieldDescriptorProto.LABEL_REPEATED:
            return False
        if field.type != FieldDescriptorProto.TYPE_MESSAGE:
            return False
        key = field.type_name.lstrip(".")
        info = self.type_map.get(key)
        if info is not None and info.kind == "map":
            return True
        return False

    def _gen_field(self, field, in_oneof: bool, siblings: list,
                   nesting: int, package: str, proto_parent: str,
                   oneof_name: str = "") -> str:
        if self._is_map_field(field):
            return self._gen_map_field(field, in_oneof, siblings, nesting,
                                        package, proto_parent, oneof_name)
        elif field.type == FieldDescriptorProto.TYPE_MESSAGE:
            return self._gen_msg_field(field, in_oneof, siblings, nesting,
                                        package, proto_parent, oneof_name)
        else:
            return self._gen_scalar_field(field, in_oneof, siblings, nesting,
                                           oneof_name)

    def _gen_scalar_field(self, field, in_oneof: bool, siblings: list,
                          nesting: int, oneof_name: str = "") -> str:
        vn = f"__{field.name}"
        gd = _gd_type(field)
        if not gd and field.type == FieldDescriptorProto.TYPE_MESSAGE:
            gd = "Variant"
        rt = f" -> {gd}" if gd else ""
        at = f" : {gd}" if gd else ""
        text = ""

        text += _tab(f"var {vn}: PBField\n", nesting)

        if field.label != FieldDescriptorProto.LABEL_REPEATED:
            text += _tab(f"func has_{field.name}() -> bool:\n", nesting)
            nesting += 1
            text += _tab(f"return data[{field.number}].state == PB_SERVICE_STATE.FILLED\n", nesting)
            nesting -= 1

        suffix = _getter_suffix(field.name)
        if field.label == FieldDescriptorProto.LABEL_REPEATED:
            array_type = f"[{gd}]" if gd else ""
            text += _tab(f"func get_{field.name}{suffix}() -> Array{array_type}:\n", nesting)
            nesting += 1
            text += _tab(f"return {vn}.value\n", nesting)
            nesting -= 1

            text += _tab(f"func clear_{field.name}() -> void:\n", nesting)
            nesting += 1
            text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
            text += _tab(f"{vn}.clear_array()\n", nesting)
            nesting -= 1

            text += _tab(f"func add_{field.name}(value{at}) -> void:\n", nesting)
            nesting += 1
            text += _tab(f"{vn}.append_array(value)\n", nesting)
        else:
            text += _tab(f"func get_{field.name}{suffix}(){rt}:\n", nesting)
            nesting += 1
            text += _tab(f"return {vn}.value\n", nesting)
            nesting -= 1

            text += _tab(f"func clear_{field.name}() -> void:\n", nesting)
            nesting += 1
            text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
            if in_oneof:
                text += _tab(f"_{oneof_name}_case = {ONE_OF_CASE_DEFAULT_VALUE}\n", nesting)
            text += _tab(f"{vn}.value = {_default_dict(self.proto_version)}[{_pb_type(field)}]\n", nesting)
            nesting -= 1

            text += _tab(f"func set_{field.name}(value{at}) -> void:\n", nesting)
            nesting += 1
            if in_oneof:
                text += self._gen_oneof_set(field, siblings, oneof_name, nesting)
            else:
                text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.FILLED\n", nesting)
            text += _tab(f"{vn}.value = value\n", nesting)

        return text

    def _gen_msg_field(self, field, in_oneof: bool, siblings: list,
                        nesting: int, package: str, proto_parent: str,
                        oneof_name: str = "") -> str:
        vn = f"__{field.name}"
        type_name = self._resolve(field.type_name)
        text = ""

        text += _tab(f"var {vn}: PBField\n", nesting)

        if field.label != FieldDescriptorProto.LABEL_REPEATED:
            if in_oneof:
                text += _tab(f"func has_{field.name}() -> bool:\n", nesting)
                nesting += 1
                text += _tab(f"return data[{field.number}].state == PB_SERVICE_STATE.FILLED\n", nesting)
                nesting -= 1
            else:
                text += _tab(f"func has_{field.name}() -> bool:\n", nesting)
                nesting += 1
                text += _tab(f"if {vn}.value != null:\n", nesting)
                nesting += 1
                text += _tab("return true\n", nesting)
                nesting -= 1
                text += _tab("return false\n", nesting)
                nesting -= 1

        suffix = _getter_suffix(field.name)
        if field.label == FieldDescriptorProto.LABEL_REPEATED:
            text += _tab(f"func get_{field.name}{suffix}() -> Array[{type_name}]:\n", nesting)
            nesting += 1
            text += _tab(f"return {vn}.value\n", nesting)
            nesting -= 1

            text += _tab(f"func clear_{field.name}() -> void:\n", nesting)
            nesting += 1
            text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
            text += _tab(f"{vn}.clear_array()\n", nesting)
            nesting -= 1

            text += _tab(f"func add_{field.name}() -> {type_name}:\n", nesting)
            nesting += 1
            text += _tab(f"var element: {type_name} = {type_name}.new()\n", nesting)
            text += _tab(f"{vn}.append_array(element)\n", nesting)
            text += _tab("return element\n", nesting)
        else:
            text += _tab(f"func get_{field.name}{suffix}() -> {type_name}:\n", nesting)
            nesting += 1
            text += _tab(f"return {vn}.value\n", nesting)
            nesting -= 1

            text += _tab(f"func clear_{field.name}() -> void:\n", nesting)
            nesting += 1
            text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
            if in_oneof:
                text += _tab(f"_{oneof_name}_case = {ONE_OF_CASE_DEFAULT_VALUE}\n", nesting)
            text += _tab(f"{vn}.value = {_default_dict(self.proto_version)}[{_pb_type(field)}]\n", nesting)
            nesting -= 1

            text += _tab(f"func new_{field.name}() -> {type_name}:\n", nesting)
            nesting += 1
            if in_oneof:
                text += self._gen_oneof_set(field, siblings, oneof_name, nesting)
            text += _tab(f"{vn}.value = {type_name}.new()\n", nesting)
            text += _tab(f"return {vn}.value\n", nesting)

        return text

    def _gen_map_class(self, msg, field_name: str, nesting: int,
                       package: str, proto_parent: str) -> str:
        """Generate a map entry wrapper class."""
        class_name = f"map_type_{field_name}"
        text = _tab(f"class {class_name}:\n", nesting)
        nesting += 1
        text += _tab("extends RefCounted\n", nesting)
        text += _tab("func _init() -> void:\n", nesting)
        nesting += 1
        text += _tab("var service: PBServiceField\n", nesting)
        text += _tab("\n", nesting)

        for field in msg.field:
            text += self._gen_field_ctor(field, nesting, package, proto_parent,
                                         is_map_entry=True)

        nesting -= 1
        text += _tab("var data: Dictionary = {}\n", nesting)
        text += _tab("\n", nesting)

        for field in msg.field:
            if field.type == FieldDescriptorProto.TYPE_MESSAGE:
                text += self._gen_msg_field(field, False, [], nesting,
                                             package, proto_parent)
            else:
                text += self._gen_scalar_field(field, False, [], nesting)
            text += _tab("\n", nesting)

        nesting -= 1
        return text

    def _gen_map_field(self, field, in_oneof: bool, siblings: list,
                       nesting: int, package: str, proto_parent: str,
                       oneof_name: str = "") -> str:
        vn = f"__{field.name}"
        class_path = self._resolve(field.type_name)
        # Replace the proto name with map_type_ name
        # The class is nested in the same parent message
        parent_gd = self._resolve(f".{package}.{proto_parent}" if proto_parent else f".{package}")
        map_class = f"map_type_{field.name}"
        if parent_gd:
            class_path = f"{parent_gd}.{map_class}"
        else:
            class_path = map_class

        text = ""

        # Find key/value info from map entry
        key_gd = ""
        val_gd = ""
        val_is_msg = False
        val_msg_type = ""

        for nested in self._get_map_entry(field, package, proto_parent):
            if nested.number == 1:
                key_gd = _gd_type(nested)
            elif nested.number == 2:
                val_gd = _gd_type(nested)
                if not val_gd and nested.type == FieldDescriptorProto.TYPE_MESSAGE:
                    val_is_msg = True
                    val_msg_type = self._resolve(nested.type_name)

        text += _tab(f"var {vn}: PBField\n", nesting)

        if in_oneof:
            text += _tab(f"func has_{field.name}() -> bool:\n", nesting)
            nesting += 1
            text += _tab(f"return data[{field.number}].state == PB_SERVICE_STATE.FILLED\n", nesting)
            nesting -= 1

        # get_raw
        text += _tab(f"func get_raw_{field.name}() -> Variant:\n", nesting)
        nesting += 1
        text += _tab(f"return {vn}.value\n", nesting)
        nesting -= 1

        # get
        suffix = _getter_suffix(field.name)
        text += _tab(f"func get_{field.name}{suffix}() -> Dictionary:\n", nesting)
        nesting += 1
        text += _tab(f"return PBPacker.construct_map({vn}.as_array())\n", nesting)
        nesting -= 1

        # clear
        text += _tab(f"func clear_{field.name}() -> void:\n", nesting)
        nesting += 1
        text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
        text += _tab(f"{vn}.value = {_default_dict(self.proto_version)}[PB_DATA_TYPE.MAP]\n", nesting)
        if in_oneof:
            text += _tab(f"_{oneof_name}_case = {ONE_OF_CASE_DEFAULT_VALUE}\n", nesting)
        nesting -= 1

        # add_empty
        text += _tab(f"func add_empty_{field.name}() -> {class_path}:\n", nesting)
        nesting += 1
        if in_oneof:
            text += self._gen_oneof_set(field, siblings, oneof_name, nesting)
        text += _tab(f"var element: {class_path} = {class_path}.new()\n", nesting)
        text += _tab(f"{vn}.append_array(element)\n", nesting)
        text += _tab("return element\n", nesting)
        nesting -= 1

        # add(key, value)
        if val_is_msg:
            text += _tab(f"func add_{field.name}(a_key: {key_gd}) -> {val_msg_type}:\n", nesting)
            nesting += 1
            if in_oneof:
                text += self._gen_oneof_set(field, siblings, oneof_name, nesting)
            text += _tab(f"var idx: int = {vn}.find_map_index(a_key)\n", nesting)
            text += _tab(f"var element: {class_path} = {class_path}.new()\n", nesting)
            text += _tab("element.set_key(a_key)\n", nesting)
            text += _tab("if idx != -1:\n", nesting)
            nesting += 1
            text += _tab(f"{vn}.set_map_element(idx, element)\n", nesting)
            nesting -= 1
            text += _tab("else:\n", nesting)
            nesting += 1
            text += _tab(f"{vn}.append_array(element)\n", nesting)
            nesting -= 1
            text += _tab("return element.new_value()\n", nesting)
        else:
            text += _tab(f"func add_{field.name}(a_key: {key_gd}, a_value: {val_gd}) -> void:\n", nesting)
            nesting += 1
            if in_oneof:
                text += self._gen_oneof_set(field, siblings, oneof_name, nesting)
            text += _tab(f"var idx: int = {vn}.find_map_index(a_key)\n", nesting)
            text += _tab(f"var element: {class_path} = {class_path}.new()\n", nesting)
            text += _tab("element.set_key(a_key)\n", nesting)
            text += _tab("element.set_value(a_value)\n", nesting)
            text += _tab("if idx != -1:\n", nesting)
            nesting += 1
            text += _tab(f"{vn}.set_map_element(idx, element)\n", nesting)
            nesting -= 1
            text += _tab("else:\n", nesting)
            nesting += 1
            text += _tab(f"{vn}.append_array(element)\n", nesting)
            nesting -= 1

        return text

    def _get_map_entry(self, field, package: str, proto_parent: str):
        """Find key/value fields in the map entry message."""
        # Walk all message types to find the map entry
        entry_name = field.type_name.lstrip(".")

        def _find(msg, pkg: str, parent: str):
            for nested in msg.nested_type:
                full = f".{pkg}.{parent}.{nested.name}"
                if full.lstrip(".") == entry_name:
                    return nested
                r = _find(nested, pkg,
                          parent + "." + msg.name if parent else msg.name)
                if r:
                    return r
            return None

        for msg in self.fd.message_type:
            result = _find(msg, package, proto_parent)
            if result:
                return result.field
        return []

    def _gen_oneof_defs(self, oneof, fields: list, nesting: int) -> str:
        pascal = _to_pascal(oneof.name)
        text = _tab(f"enum {pascal}{ONE_OF_CASE_ENUM_FIELD_SUFFIX} {{\n", nesting)
        nesting += 1
        text += _tab(f"{_to_snake_upper(oneof.name)}_NOT_SET = 0,\n", nesting)
        for f in fields:
            text += _tab(f"{f.name.upper()} = {f.number},\n", nesting)
        nesting -= 1
        text += _tab("}\n", nesting)
        text += _tab(f"var _{oneof.name}{ONE_OF_CASE_INNER_FIELD_SUFFIX}: int = {ONE_OF_CASE_DEFAULT_VALUE}\n", nesting)
        return text

    def _gen_oneof_getter(self, oneof, nesting: int) -> str:
        text = _tab(f"func get_{oneof.name}{ONE_OF_CASE_FUNCTION_SUFFIX}() -> int:\n", nesting)
        nesting += 1
        text += _tab(f"return _{oneof.name}{ONE_OF_CASE_INNER_FIELD_SUFFIX}\n", nesting)
        return text

    def _gen_oneof_set(self, current_field, siblings: list, oneof_name: str,
                       nesting: int) -> str:
        text = ""
        # Combine own and other-sibling fields, sorted by field number
        all_fields = [(f.number, f, False) for f in siblings if f.name != current_field.name]
        all_fields.append((current_field.number, current_field, True))
        all_fields.sort(key=lambda x: x[0])
        for _, field, is_own in all_fields:
            if is_own:
                text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.FILLED\n", nesting)
                text += _tab(f"_{oneof_name}_case = {field.number}\n", nesting)
            else:
                text += _tab(f"__{field.name}.value = {_default_dict(self.proto_version)}[{_pb_type(field)}]\n", nesting)
                text += _tab(f"data[{field.number}].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
        return text

    def gen_class_services(self, nesting: int, msg=None) -> str:
        text = ""
        text += _tab("func _to_string() -> String:\n", nesting)
        nesting += 1
        text += _tab("return PBPacker.message_to_string(data)\n", nesting)
        text += _tab("\n", nesting)
        nesting -= 1

        text += _tab("func to_bytes() -> PackedByteArray:\n", nesting)
        nesting += 1
        text += _tab("return PBPacker.pack_message(data)\n", nesting)
        text += _tab("\n", nesting)
        nesting -= 1

        text += _tab("func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:\n", nesting)
        nesting += 1
        text += _tab("var cur_limit: int = bytes.size()\n", nesting)
        text += _tab("if limit != -1:\n", nesting)
        nesting += 1
        text += _tab("cur_limit = limit\n", nesting)
        nesting -= 1
        text += _tab("var result: int = PBPacker.unpack_message(data, bytes, offset, cur_limit)\n", nesting)
        text += _tab("if result == cur_limit:\n", nesting)
        nesting += 1

        # Oneof sync: restore _case variables after unpack
        if msg is not None:
            for oi, oneof in enumerate(msg.oneof_decl):
                case_var = f"_{oneof.name}_case"
                pascal = _to_pascal(oneof.name)
                text += _tab(f"{case_var} = {ONE_OF_CASE_DEFAULT_VALUE}\n", nesting)
                for field in msg.field:
                    if field.HasField("oneof_index") and field.oneof_index == oi:
                        text += _tab(f"if data[{field.number}].state == PB_SERVICE_STATE.FILLED:\n", nesting)
                        nesting += 1
                        text += _tab(f"{case_var} = {field.number}\n", nesting)
                        nesting -= 1

        text += _tab("if PBPacker.check_required(data):\n", nesting)
        nesting += 1
        text += _tab("if limit == -1:\n", nesting)
        nesting += 1
        text += _tab("return PB_ERR.NO_ERRORS\n", nesting)
        nesting -= 2
        text += _tab("else:\n", nesting)
        nesting += 1
        text += _tab("return PB_ERR.REQUIRED_FIELDS\n", nesting)
        nesting -= 2
        text += _tab("elif limit == -1 && result > 0:\n", nesting)
        nesting += 1
        text += _tab("return PB_ERR.PARSE_INCOMPLETE\n", nesting)
        nesting -= 1
        text += _tab("return result\n", nesting)
        return text
