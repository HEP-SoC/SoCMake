import argparse
from typing import Any, Dict, List, Tuple, Optional
import yaml
from pathlib import Path

import re


def removesuffix(s: str, suffix: str) -> str:
    """Backport of str.removesuffix for Python < 3.9"""
    if suffix and s.endswith(suffix):
        return s[:-len(suffix)]
    return s


def convert_language(lang: str) -> str:
    """Convert a FuseSoC file type string to a SoCMake language name.

    Strips the trailing ``Source`` suffix and uppercases the result.
    For example, ``systemVerilogSource`` becomes ``SYSTEMVERILOG``.

    Args:
        lang: FuseSoC file type string (e.g. ``systemVerilogSource``).

    Returns:
        SoCMake language name (e.g. ``SYSTEMVERILOG``).
    """
    lang = removesuffix(lang, "Source")
    lang = lang.upper()
    return lang


def convert_fusesoc_vlnv_to_socmake_add_ip_args(vlnv: str) -> str:
    """Convert a FuseSoC VLNV string to SoCMake ``add_ip()`` named argument string.

    Args:
        vlnv: FuseSoC VLNV string in ``vendor:library:name:version`` form.

    Returns:
        String of named CMake keyword arguments (e.g. ``name VENDOR v LIBRARY l VERSION ver``).
    """
    parts: list[str] = vlnv.split(":")

    vendor: str = f"VENDOR {parts[0]}" if parts[0] else ""
    lib: str = f"LIBRARY {parts[1]}" if parts[1] else ""
    name: str = f"{parts[2]}"
    if len(parts) == 4:
        version: str = f"VERSION {parts[3]}" if parts[3] else ""
    else:
        version = ""

    return f"{name} {vendor} {lib} {version}"


def convert_fusesoc_vlnv_to_socmake_ip(vlnv: str) -> str:
    """Convert a FuseSoC VLNV string to a SoCMake IP reference argument string.

    Args:
        vlnv: FuseSoC VLNV string in ``vendor:library:name:version`` form.

    Returns:
        String of named CMake keyword arguments (e.g. ``name VENDOR v LIBRARY l VERSION ver``).
    """
    parts: list[str] = vlnv.split(":")

    vendor: str = f"VENDOR {parts[0]}" if parts[0] else ""
    lib: str = f"LIBRARY {parts[1]}" if parts[1] else ""
    name: str = f"{parts[2]}"
    if len(parts) == 4:
        version: str = f"VERSION {parts[3]}" if parts[3] else ""
    else:
        version = ""

    return f"{name} {vendor} {lib} {version}"


def move_prefix_to_end(s: str) -> str:
    """Strip a version constraint operator prefix from a VLNV string.

    Recognizes operators ``>=``, ``<=``, ``>``, ``<``, ``~``, ``^`` at the
    start of the string and removes them.

    Args:
        s: VLNV string optionally prefixed with a version constraint operator.

    Returns:
        The VLNV string with the leading operator removed.
    """
    # Match any of the operators at the start
    match = re.match(r'^(>=|<=|>|<|~|\^)(.*)$', s)
    if match:
        op, rest = match.groups()
        # return rest + op
        return rest
    return s


def convert_depend_vlnv(vlnv: str) -> str:
    """Convert a FuseSoC dependency VLNV string to SoCMake ``::``-separated format.

    Strips any leading version constraint operator and joins non-empty VLNV
    components with ``::``.

    Args:
        vlnv: FuseSoC dependency VLNV string (e.g. ``>=vendor:library:name:1.0``).

    Returns:
        SoCMake-style VLNV string (e.g. ``vendor::library::name::1.0``).
    """
    dep: str = move_prefix_to_end(vlnv)
    dep = "::".join([x for x in dep.split(":") if x])
    return dep


def append_and_create(dict_ref: Dict[Any, List[Any]], key: Any, val: Any) -> None:
    """Append a value to a list in a dictionary, creating the list if the key is absent.

    Does nothing if ``val`` is already present in ``dict_ref[key]``.

    Args:
        dict_ref: The dictionary to update in place.
        key: The key under which to append ``val``.
        val: The value to append.
    """
    if key not in dict_ref:
        dict_ref[key] = [val]
    else:
        if val not in dict_ref[key]:
            dict_ref[key].append(val)


def fusesoc_to_socmake(input_file: Path):
    """Parse a FuseSoC ``.core`` YAML file and print equivalent SoCMake CMake commands to stdout.

    Reads the FuseSoC core description and emits the corresponding
    ``add_ip``, ``ip_sources``, ``ip_include_directories``, and ``ip_link``
    CMake calls.

    Args:
        input_file: Path to the FuseSoC ``.core`` YAML file.
    """
    with open(input_file, "r") as f:
        core_data = yaml.safe_load(f)

    ip_vlnv: str = core_data.get('name')
    ip_description: str | None = core_data.get('description', None)
    if ip_description:
        ip_description = ip_description.replace(";", "")
    add_ip_vlnv_args: str = convert_fusesoc_vlnv_to_socmake_add_ip_args(ip_vlnv)

    description_arg: str = ""
    if ip_description:
        description_arg = f'DESCRIPTION "{ip_description}"'
    # print(f'add_ip({add_ip_vlnv_args} {description_arg} NO_ALIAS)\n')
    print(f'add_ip({add_ip_vlnv_args} {description_arg})\n')

    dependencies: list[str] = []
    # Dictionary of (language, fileset, headers) -> list[files...]
    files_list: dict[tuple[str, str, bool], list[str]] = {}
    # Dictionary of (language, fileset) -> list[dirs...]
    incdirs: dict[tuple[str, str], list[str]] = {}

    # Handle filesets
    filesets = core_data.get("filesets", {})
    for file_set_name, fs_data in filesets.items():
        files = fs_data.get("files", [])
        file_set_file_type: str | None = fs_data.get("file_type", None)

        depend: list[str] | None = fs_data.get("depend", None)
        if depend:
            for dep in depend:
                dep_vlnv: str = convert_depend_vlnv(dep)
                if dep_vlnv not in dependencies:
                    dependencies.append(dep_vlnv)

        if files:
            for f in files:
                if isinstance(f, dict):
                    file_path = list(f.keys())[0]
                    is_include_file: bool = f[file_path].get("is_include_file", False)
                    file_type: str | None = f[file_path].get("file_type", file_set_file_type)
                    assert file_type
                    incpath: str | None = f[file_path].get("include_path", None)
                    append_and_create(files_list, (convert_language(file_type), file_set_name, is_include_file), file_path)
                    if incpath:
                        append_and_create(incdirs, (convert_language(file_type), file_set_name), incpath)
                else:
                    assert file_set_file_type
                    append_and_create(files_list, (convert_language(file_set_file_type), file_set_name, False), f)

    for file_attributes, files in files_list.items():
        print(f'ip_sources(${{IP}} {file_attributes[0]} FILE_SET {file_attributes[1]} {"HEADERS" if file_attributes[2] else ""}') #)
        for file in files:
            print(f"    ${{CMAKE_CURRENT_LIST_DIR}}/{file}")
        print(")\n")

    for file_attributes, dirs in incdirs.items():
        print(f'ip_include_directories(${{IP}} {file_attributes[0]} FILE_SET {file_attributes[1]}')  # )
        for dir in dirs:
            print(f"    ${{CMAKE_CURRENT_LIST_DIR}}/{dir}")
        print(")\n")

    if dependencies:
        print("ip_link(${IP}")  # )
        for dep in dependencies:
            print(f"    {dep}")
        print(")\n")


def main():
    """Entry point: parse command-line arguments and run the FuseSoC-to-SoCMake conversion."""
    parser = argparse.ArgumentParser(
        description="Convert FuseSoC .core (YAML) files to SoCMake CMakeLists.txt"
    )
    parser.add_argument("input", type=Path, help="Path to FuseSoC .core YAML file")

    args = parser.parse_args()
    fusesoc_to_socmake(args.input)


if __name__ == "__main__":
    main()
