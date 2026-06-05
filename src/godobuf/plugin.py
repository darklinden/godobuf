"""protoc plugin entry point — reads CodeGeneratorRequest, writes CodeGeneratorResponse."""

import sys

from google.protobuf.compiler.plugin_pb2 import (
    CodeGeneratorRequest,
    CodeGeneratorResponse,
)
from google.protobuf.descriptor_pb2 import FileDescriptorProto

from .core_template import prepare_core
from .generator import Generator, build_type_map


def _syntax_to_version(fd: FileDescriptorProto) -> int:
    if fd.syntax == "proto2":
        return 2
    return 3


def _load_core_text() -> str:
    """Read godobuf_core.gd from the package data directory."""
    import os
    # Try relative to this file first
    here = os.path.dirname(os.path.abspath(__file__))
    # Look in package dir
    candidate = os.path.join(here, "godobuf_core.gd")
    if os.path.isfile(candidate):
        return _read_file(candidate)
    # Look relative to cwd
    candidate = "addons/godobuf/godobuf_core.gd"
    if os.path.isfile(candidate):
        return _read_file(candidate)
    raise FileNotFoundError(
        "godobuf_core.gd not found. Pass --core_file via --gd_opt=core_file=..."
    )


def _read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def main() -> None:
    """protoc plugin main: read request from stdin, write response to stdout."""
    data = sys.stdin.buffer.read()
    request = CodeGeneratorRequest()
    request.ParseFromString(data)

    # Parse plugin parameters
    params: dict[str, str] = {}
    if request.parameter:
        for part in request.parameter.split(","):
            if "=" in part:
                k, v = part.split("=", 1)
                params[k.strip()] = v.strip()
            else:
                params[part.strip()] = "true"

    prefix = params.get("prefix", "")
    should_prefix_enums = params.get("should_prefix_enums", "false").lower() == "true"
    custom_class_name = params.get("class_name", "")
    should_add_wia = params.get("warning_ignore", "false").lower() == "true"
    core_file = params.get("core_file", "")

    # Load core template
    if core_file:
        core_text = _read_file(core_file)
    else:
        core_text = _load_core_text()

    # Collect all file descriptors
    all_fds: list[FileDescriptorProto] = []
    for fd in request.proto_file:
        all_fds.append(fd)

    # Build type map across all files
    type_map = build_type_map(all_fds, prefix)

    # Build file name → FileDescriptorProto lookup
    fd_by_name: dict[str, FileDescriptorProto] = {fd.name: fd for fd in all_fds}

    response = CodeGeneratorResponse()
    response.supported_features = CodeGeneratorResponse.FEATURE_PROTO3_OPTIONAL

    for file_name in request.file_to_generate:
        fd = fd_by_name.get(file_name)
        if fd is None:
            response.error = f"File '{file_name}' not found in request."
            sys.stdout.buffer.write(response.SerializeToString())
            sys.exit(1)

        proto_version = _syntax_to_version(fd)
        gen = Generator(fd, type_map, proto_version, prefix, should_prefix_enums)

        # Generate user classes/enums section
        user_code = gen.generate()

        # Prepend core template and wrap with markers
        output = prepare_core(core_text, proto_version,
                              should_add_wia, custom_class_name)
        output += "\n\n\n"
        output += "############### USER DATA BEGIN ################\n"
        output += "\n\n"
        output += user_code
        output += "\t\n"
        output += "################ USER DATA END #################\n"

        # Determine output file name
        base = file_name.rsplit(".", 1)[0] if "." in file_name else file_name
        out_name = base + ".gd"

        resp_file = response.file.add()
        resp_file.name = out_name
        resp_file.content = output

    sys.stdout.buffer.write(response.SerializeToString())


if __name__ == "__main__":
    main()
