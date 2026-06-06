"""protoc plugin entry point — reads CodeGeneratorRequest, writes CodeGeneratorResponse."""

import sys

from google.protobuf.compiler.plugin_pb2 import (
    CodeGeneratorRequest,
    CodeGeneratorResponse,
)
from google.protobuf.descriptor_pb2 import FileDescriptorProto

from .generator import Generator, build_type_map


def _syntax_to_version(fd: FileDescriptorProto) -> int:
    if fd.syntax == "proto2":
        return 2
    return 3


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
    # core_file now specifies the preload path for godobuf_core.gd in the Godot project
    core_path = params.get("core_file", "res://addons/godobuf/godobuf_core.gd")

    # Deprecated: warning_ignore annotations now live on godobuf_core.gd itself
    if "warning_ignore" in params:
        print(
            "godobuf: --gd_opt=warning_ignore is deprecated and has no effect. "
            "Warning suppression annotations are now baked into godobuf_core.gd.",
            file=sys.stderr,
        )

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
        gen = Generator(fd, type_map, proto_version, prefix,
                        should_prefix_enums, core_path)

        # Generate user classes/enums section (includes core preload + PROTO_VERSION)
        user_code = gen.generate()

        output = ""
        if custom_class_name:
            output += "class_name " + custom_class_name + "\n\n"
        output += user_code

        # Determine output file name
        base = file_name.rsplit(".", 1)[0] if "." in file_name else file_name
        out_name = base + ".gd"

        resp_file = response.file.add()
        resp_file.name = out_name
        resp_file.content = output

    sys.stdout.buffer.write(response.SerializeToString())


if __name__ == "__main__":
    main()
