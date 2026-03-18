import re
import sys
from pathlib import Path


def clean_file(text: str) -> str:
    lines = text.splitlines()
    cleaned = []

    for line in lines:
        # Remove inline // comments (not inside strings)
        line = remove_line_comment(line)

        # Strip trailing whitespace
        line = line.rstrip()
        cleaned.append(line)

    # Collapse multiple blank lines into one
    result = []
    prev_blank = False
    for line in cleaned:
        is_blank = line.strip() == ""
        if is_blank:
            if not prev_blank:
                result.append("")
            prev_blank = True
        else:
            result.append(line)
            prev_blank = False

    # Remove leading/trailing blank lines
    while result and result[0] == "":
        result.pop(0)
    while result and result[-1] == "":
        result.pop()

    return "\n".join(result) + "\n"


def remove_line_comment(line: str) -> str:
    """Remove // comment from a line, respecting strings."""
    in_single = False
    in_double = False
    i = 0

    while i < len(line):
        ch = line[i]

        if ch == "\\" and (in_single or in_double):
            i += 2
            continue

        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "/" and not in_single and not in_double:
            if i + 1 < len(line) and line[i + 1] == "/":
                return line[:i]

        i += 1

    return line


def process(path: str) -> None:
    p = Path(path)
    if not p.exists():
        print(f"File not found: {path}")
        sys.exit(1)

    original = p.read_text(encoding="utf-8")
    cleaned = clean_file(original)

    p.write_text(cleaned, encoding="utf-8")

    orig_lines = len(original.splitlines())
    new_lines = len(cleaned.splitlines())
    print(f"Done: {path}")
    print(f"  {orig_lines} lines -> {new_lines} lines ({orig_lines - new_lines} removed)")


def scan_project(root: str) -> None:
    lib_dir = Path(root) / "lib"
    if not lib_dir.exists():
        print(f"No 'lib' folder found in: {root}")
        sys.exit(1)

    files = list(lib_dir.rglob("*.dart"))
    if not files:
        print("No .dart files found in lib/")
        sys.exit(1)

    print(f"Found {len(files)} .dart files in {lib_dir}\n")
    total_removed = 0

    for f in sorted(files):
        original = f.read_text(encoding="utf-8")
        cleaned = clean_file(original)
        orig_lines = len(original.splitlines())
        new_lines = len(cleaned.splitlines())
        removed = orig_lines - new_lines
        total_removed += removed
        if original != cleaned:
            f.write_text(cleaned, encoding="utf-8")
            print(f"  cleaned  {f.relative_to(root)}  ({removed} lines removed)")
        else:
            print(f"  ok       {f.relative_to(root)}")

    print(f"\nDone. {total_removed} lines removed across {len(files)} files.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        # Default: scan current directory
        scan_project(".")
    else:
        arg = sys.argv[1]
        p = Path(arg)
        if p.is_dir():
            scan_project(arg)
        else:
            process(arg)