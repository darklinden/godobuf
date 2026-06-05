"""Path utilities."""

import os


def extract_dir(path: str) -> str:
    """Extract the directory part of a path, ensuring a trailing separator."""
    d = os.path.dirname(path)
    if d and not d.endswith(os.sep):
        d += os.sep
    return d


def extract_filename(path: str) -> str:
    """Extract the filename (without directory) from a path."""
    return os.path.basename(path)


def normalize_dir_path(path: str) -> str:
    """Ensure path ends with a directory separator."""
    if path and not path.endswith(os.sep):
        return path + os.sep
    return path
