import os
from pathlib import Path
import pytest
import hy

def pytest_collect_file(file_path, parent):
    if (file_path.suffix == ".hy" and file_path.name != "__init__.hy"):

        return pytest.Module.from_parent(parent, path=file_path)
