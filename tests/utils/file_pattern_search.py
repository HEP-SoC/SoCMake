import argparse
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.text import Text

def check_search(file_content, search_term):
    """Check if a search term exists in the file content and return matching lines with their line numbers."""
    matched_lines = []
    for line_number, line in enumerate(file_content.splitlines(), start=1):
        if search_term in line:
            matched_lines.append((line_number, line))
    return matched_lines

def generate_report(results):
    """Generate a detailed report from the search results with colored output."""
    report = []
    report.append("Search Report")
    report.append("=" * 40)
    
    return_status = 0
    for term, (found, _) in results.items():
        if found:
            # Green [OK] message for matches
            status = Text("[green][OK][/green]         Found: ")
        else:
            # Red [FAILED] message for mismatches
            status = Text("[red][FAILED][/red] Not found: ")
            return_status = -1
        
        # Add the search term to the status
        report.append(Text.assemble(status, term))
    
    report.append("=" * 40)
    
    # Return the full report as a string
    return "\n".join(str(line) for line in report), return_status

def highlight_patterns(line, patterns):
    """Highlight matched and unmatched patterns in the given line."""
    line = f"[red]{line}[/red]"
    for pattern in patterns:
        if pattern in line:
            line = line.replace(pattern, f"[green]{pattern}[/green]")
    return line

def main():
    parser = argparse.ArgumentParser(description="Search for multiple patterns in a file and report results.")
    parser.add_argument('file', type=Path, help="Path to the file to search")
    parser.add_argument('patterns', nargs='+', help="Patterns to search for")
    
    args = parser.parse_args()

    console = Console(force_terminal=True)

    # Check if the file exists
    if not args.file.is_file():
        console.print(f"[red]Error: File '{args.file}' does not exist.[/red]")
        return

    # Read file content
    with args.file.open('r') as file:
        file_content = file.read()

    # Perform the searches and collect unique matching lines
    results = {}
    matched_lines_set = set()  # To store unique matched lines
    for pattern in args.patterns:
        matched_lines = check_search(file_content, pattern)
        results[pattern] = (bool(matched_lines), matched_lines)
        matched_lines_set.update(matched_lines)  # Add to the set to avoid duplicates

    # Generate and print the report
    report, return_status = generate_report(results)
    console.print(Text("CTEST_FULL_OUTPUT"))
    console.print(Panel(report, title="Pattern Search Results", expand=False))

    # Print the final separator after the report
    console.print("=" * 40)

    # Print the unique matched lines, if any
    if matched_lines_set:
        for line_number, line in matched_lines_set:
            highlighted_line = highlight_patterns(line, args.patterns)
            # console.print(f"[yellow]{line_number}: {highlighted_line}[/yellow]")
            console.print(Panel(f"[yellow]{line_number}: {highlighted_line}[/yellow]", title="Matched Lines", expand=False))
    else:
        console.print("[yellow]No matching lines found in the file.[/yellow]")

    exit(return_status)

if __name__ == "__main__":
    main()

