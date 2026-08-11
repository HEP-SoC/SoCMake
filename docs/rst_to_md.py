#!/usr/bin/env python3
"""Convert cminx-generated RST files to Docusaurus-compatible Markdown.

Usage: python3 rst_to_md.py <rst_input_dir> <md_output_dir>
"""

import json
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Inline markup
# ---------------------------------------------------------------------------

RE_LINK = re.compile(r"`([^`<]+?)\s*<([^>]+)>`_")
RE_DBL_BT = re.compile(r"``([^`]+?)``")
RE_CODE_SPAN = re.compile(r"(`[^`]+`)")
RE_JSX_OPEN = re.compile(r"<")
# MDX evaluates {expr} as JavaScript.  \{ does NOT escape it in MDX v3;
# use the HTML entity &#123; instead (Docusaurus recommendation).
RE_JSX_EXPR = re.compile(r"\{")


def _escape_prose(text: str) -> str:
    """Escape MDX-special chars in prose, leaving inline code spans untouched."""
    segments = RE_CODE_SPAN.split(text)
    result = []
    for i, seg in enumerate(segments):
        if i % 2 == 1:  # captured code span — leave verbatim
            result.append(seg)
        else:
            seg = RE_JSX_OPEN.sub(r"\\<", seg)
            seg = RE_JSX_EXPR.sub("&#123;", seg)
            result.append(seg)
    return "".join(result)


def inline_to_md(text: str) -> str:
    """Convert RST inline markup to Markdown."""
    # `text <url>`_ → [text](url)  (must run before JSX escaping)
    text = RE_LINK.sub(lambda m: f"[{m.group(1).strip()}]({m.group(2)})", text)
    # ``code`` → `code`
    text = RE_DBL_BT.sub(lambda m: f"`{m.group(1)}`", text)
    # Escape < and { in prose (not inside backtick code spans)
    text = _escape_prose(text)
    return text


# ---------------------------------------------------------------------------
# RST title extraction
# ---------------------------------------------------------------------------

UNDERLINE_CHARS = set('#=-~^"')


def is_underline(line: str) -> bool:
    s = line.rstrip()
    return len(s) >= 2 and all(c in UNDERLINE_CHARS for c in s)


def get_rst_title(lines: list) -> str | None:
    """Return the first RST section title (handles overline/underline and underline-only)."""
    for i, line in enumerate(lines):
        if (
            is_underline(line)
            and i > 0
            and lines[i - 1].strip()
            and not is_underline(lines[i - 1])
        ):
            return lines[i - 1].strip()
    return None


# ---------------------------------------------------------------------------
# Code block extraction
# ---------------------------------------------------------------------------


def collect_indented_block(lines: list, start: int) -> tuple:
    """Collect an indented block (code) after optional blank lines.

    Returns (code_lines, next_index).
    """
    i = start
    while i < len(lines) and not lines[i].strip():
        i += 1
    if i >= len(lines):
        return [], i

    base_indent = len(lines[i]) - len(lines[i].lstrip())
    code_lines = []

    while i < len(lines):
        line = lines[i]
        if not line.strip():
            code_lines.append("")
            i += 1
        else:
            indent = len(line) - len(line.lstrip())
            if indent >= base_indent:
                code_lines.append(line[base_indent:])
                i += 1
            else:
                break

    while code_lines and not code_lines[-1].strip():
        code_lines.pop()

    return code_lines, i


# ---------------------------------------------------------------------------
# Description block conversion
# ---------------------------------------------------------------------------


def desc_to_md(lines: list) -> str:
    """Convert dedented RST description lines to Markdown text."""
    parts = []
    i = 0

    while i < len(lines):
        line = lines[i]
        s = line.strip()

        # Skip the **Keyword Arguments** section divider
        if s == "**Keyword Arguments**":
            i += 1
            continue

        # Explicit code-block directive: .. code-block:: lang
        if s.startswith(".. code-block::"):
            lang = s[len(".. code-block::") :].strip() or "cmake"
            code, i = collect_indented_block(lines, i + 1)
            parts += [f"```{lang}"] + code + ["```", ""]
            continue

        # Literal block via trailing ::
        if s.endswith("::") and not s.startswith(".."):
            label = s[:-2].rstrip()
            if label:
                parts.append(inline_to_md(label) + ":")
                parts.append("")
            code, i = collect_indented_block(lines, i + 1)
            parts += ["```cmake"] + code + ["```", ""]
            continue

        # Standalone :: on its own line
        if s == "::":
            code, i = collect_indented_block(lines, i + 1)
            parts += ["```cmake"] + code + ["```", ""]
            continue

        # RST bullet list item
        if s.startswith("* "):
            parts.append("- " + inline_to_md(s[2:]))
            i += 1
            continue

        # Blank line
        if not s:
            parts.append("")
            i += 1
            continue

        # Regular text
        parts.append(inline_to_md(s))
        i += 1

    # Strip surrounding blank lines
    while parts and not parts[0]:
        parts.pop(0)
    while parts and not parts[-1]:
        parts.pop()

    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Parameter field list parsing
# ---------------------------------------------------------------------------


def parse_params(lines: list) -> tuple:
    """Parse :param:/:type: and :keyword:/:type: field lists.

    Returns (positional_params, keyword_params) as lists of dicts with
    keys 'name', 'type', 'desc'.
    """
    pos: dict = {}
    kw: dict = {}
    last_name: str | None = None
    last_is_kw: bool = False

    for line in lines:
        s = line.strip()
        if not s:
            continue

        m = re.match(r":param (\w+):\s*(.*)", s)
        if m:
            last_name, last_is_kw = m.group(1), False
            pos.setdefault(last_name, {})["desc"] = inline_to_md(m.group(2).strip())
            continue

        m = re.match(r":keyword (\w+):\s*(.*)", s)
        if m:
            last_name, last_is_kw = m.group(1), True
            kw.setdefault(last_name, {})["desc"] = inline_to_md(m.group(2).strip())
            continue

        m = re.match(r":type (\w+):\s*(.*)", s)
        if m:
            name, typ = m.group(1), m.group(2).strip()
            if last_is_kw and name == last_name:
                kw.setdefault(name, {})["type"] = typ
            elif name in kw and name not in pos:
                kw[name]["type"] = typ
            else:
                pos.setdefault(name, {})["type"] = typ
            continue

    def to_list(d: dict) -> list:
        return [
            {"name": k, "type": v.get("type", ""), "desc": v.get("desc", "")}
            for k, v in d.items()
        ]

    return to_list(pos), to_list(kw)


def params_to_table(params: list) -> str:
    rows = ["| Name | Type | Description |", "|------|------|-------------|"]
    for p in params:
        rows.append(f"| `{p['name']}` | {p['type'] or '—'} | {p['desc'] or '—'} |")
    return "\n".join(rows)


# ---------------------------------------------------------------------------
# Function block → Markdown section
# ---------------------------------------------------------------------------


def func_to_md(signature: str, body_lines: list) -> str:
    """Convert a .. function:: body to a Markdown ## section."""
    # Dedent by 3 spaces (cminx indents function bodies by 3)
    dedented = []
    for line in body_lines:
        if line.startswith("   "):
            dedented.append(line[3:])
        elif not line.strip():
            dedented.append("")
        else:
            dedented.append(line.lstrip())

    # Find the split between description and parameter fields.
    # The field list starts at the first :param:, :keyword:, or **Keyword Arguments**.
    split = len(dedented)
    for idx, line in enumerate(dedented):
        s = line.strip()
        if s == "**Keyword Arguments**":
            # Trim trailing blanks to get the true end of description
            j = idx - 1
            while j >= 0 and not dedented[j].strip():
                j -= 1
            split = j + 1
            break
        if s.startswith(":param ") or s.startswith(":keyword "):
            split = idx
            break

    desc_lines = dedented[:split]
    param_lines = dedented[split:]

    while desc_lines and not desc_lines[-1].strip():
        desc_lines.pop()

    desc_md = desc_to_md(desc_lines)
    pos_params, kw_params = parse_params(param_lines)

    parts = [f"## `{signature}`", ""]
    if desc_md:
        parts += [desc_md, ""]
    if pos_params:
        parts += ["### Parameters", "", params_to_table(pos_params), ""]
    if kw_params:
        parts += ["### Keyword Arguments", "", params_to_table(kw_params), ""]

    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Full RST file → Markdown
# ---------------------------------------------------------------------------


def rst_file_to_md(rst_text: str, module_name: str, sidebar_position: int) -> str:
    """Convert a full cminx RST file to a Docusaurus Markdown page."""
    lines = rst_text.split("\n")
    title = get_rst_title(lines) or module_name

    # Locate all .. function:: directive positions
    func_starts = [
        i for i, line in enumerate(lines) if line.strip().startswith(".. function::")
    ]

    md: list = [
        "---",
        f"title: {title}",
        f"sidebar_label: {module_name}",
        f"sidebar_position: {sidebar_position}",
        "---",
        "",
    ]

    for j, fs in enumerate(func_starts):
        signature = lines[fs].strip()[len(".. function::") :].strip()
        end = func_starts[j + 1] if j + 1 < len(func_starts) else len(lines)
        body = lines[fs + 1 : end]
        while body and not body[-1].strip():
            body.pop()

        if j > 0:
            md += ["---", ""]

        md.append(func_to_md(signature, body))

    return "\n".join(md)


# ---------------------------------------------------------------------------
# Category label helpers
# ---------------------------------------------------------------------------

# Override title-cased directory names for well-known acronyms/brands
LABEL_OVERRIDES = {
    "fpga": "FPGA",
    "fusesoc": "FuseSoC",
    "ipxact": "IP-XACT",
    "peakrdl": "PeakRDL",
    "systemrdl": "SystemRDL",
    "ghdl": "GHDL",
    "iverilog": "Icarus Verilog",
    "cocotb": "CocoTB",
    "fc4sc": "FC4SC",
    "cadence": "Cadence",
    "siemens": "Siemens",
    "synopsys": "Synopsys",
    "xilinx": "Xilinx",
    "verilator": "Verilator",
}


def dir_label(dir_name: str, rst_title: str | None) -> str:
    """Return a human-readable sidebar label for a directory."""
    if dir_name in LABEL_OVERRIDES:
        return LABEL_OVERRIDES[dir_name]
    # Strip "cmake." prefix from RST titles like "cmake.sim" → "Sim"
    if rst_title and "." in rst_title:
        suffix = rst_title.split(".")[-1]
        return suffix.replace("_", " ").title()
    if rst_title:
        return rst_title.replace("_", " ").title()
    return dir_name.replace("_", " ").title()


# ---------------------------------------------------------------------------
# Directory traversal
# ---------------------------------------------------------------------------


def process_dir(
    rst_dir: Path, md_dir: Path, is_root: bool = True, position: int = 1
) -> None:
    """Recursively convert an RST directory tree to Markdown."""
    md_dir.mkdir(parents=True, exist_ok=True)

    index_rst = rst_dir / "index.rst"
    rst_title = None
    if index_rst.exists():
        rst_title = get_rst_title(index_rst.read_text("utf-8").split("\n"))

    if is_root:
        # Generate an index page so /docs/api is a valid route (breadcrumbs link to it)
        index_md = (
            "---\n"
            "title: API Reference\n"
            "sidebar_label: Overview\n"
            "sidebar_position: 0\n"
            "---\n\n"
            "# SoCMake API Reference\n\n"
            "This reference is auto-generated from the CMake function docstrings using\n"
            "[cminx](https://github.com/CMakePP/CMinx).\n\n"
            "Browse the categories in the sidebar to find specific functions.\n"
        )
        (md_dir / "index.md").write_text(index_md, "utf-8")
    else:
        # Write _category_.json for all non-root directories
        label = dir_label(rst_dir.name, rst_title)
        category = {
            "label": label,
            "position": position,
            "link": {"type": "generated-index"},
        }
        (md_dir / "_category_.json").write_text(
            json.dumps(category, indent=2) + "\n", "utf-8"
        )

    # Convert individual .rst files (skip index.rst)
    file_pos = 1
    for rst_file in sorted(rst_dir.glob("*.rst")):
        if rst_file.name == "index.rst":
            continue
        md_path = md_dir / (rst_file.stem + ".md")
        text = rst_file.read_text("utf-8")
        md_text = rst_file_to_md(text, rst_file.stem, file_pos)
        md_path.write_text(md_text, "utf-8")
        print(f"  {rst_file.relative_to(rst_dir.parent.parent)} → {md_path.name}")
        file_pos += 1

    # Recurse into subdirectories
    sub_pos = file_pos
    for sub in sorted(d for d in rst_dir.iterdir() if d.is_dir()):
        process_dir(sub, md_dir / sub.name, is_root=False, position=sub_pos)
        sub_pos += 1


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <rst_input_dir> <md_output_dir>")
        sys.exit(1)

    rst_dir = Path(sys.argv[1]).resolve()
    md_dir = Path(sys.argv[2]).resolve()

    if not rst_dir.exists():
        print(f"Error: RST directory not found: {rst_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Converting {rst_dir} → {md_dir}")
    process_dir(rst_dir, md_dir, is_root=True)
    print("Done.")


if __name__ == "__main__":
    main()
