"""Core template handling for godobuf — reads godobuf_core.gd and preprocesses it."""

PROTO_VERSION_CONST = "const PROTO_VERSION: int = "
PROTO_VERSION_DEFAULT = "const PROTO_VERSION: int = 0"

WARNING_IGNORE_ANNOTATIONS = """\
@warning_ignore_start("inferred_declaration", "untyped_declaration")
@warning_ignore_start("unsafe_property_access")
@warning_ignore_start("unsafe_method_access")
@warning_ignore_start("unsafe_cast")
@warning_ignore_start("unsafe_call_argument")
"""


def prepare_core(
    core_text: str,
    proto_version: int,
    should_add_warning_ignore_annotations: bool = False,
    custom_class_name: str = "",
) -> str:
    """Preprocess the core template for a generated .gd file."""
    # Replace PROTO_VERSION placeholder
    core_text = core_text.replace(
        PROTO_VERSION_DEFAULT,
        PROTO_VERSION_CONST + str(proto_version),
    )

    result = ""

    # Optional class_name at the very top
    if custom_class_name:
        result += "class_name " + custom_class_name + "\n\n"

    # Optional warning ignore annotations
    if should_add_warning_ignore_annotations:
        result += WARNING_IGNORE_ANNOTATIONS

    result += core_text
    return result
