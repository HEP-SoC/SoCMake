import argparse
import shutil
import subprocess
import os
import sys

def make_parser():
    parser = argparse.ArgumentParser(description="Filter RTL files based on module hierarchy.")
    parser.add_argument("--top-module", dest="top_module", action="store", help="Specify top module name")
    parser.add_argument("--synthesis", dest="synthesis", action="store_true", help="Define SYNTHESIS")
    parser.add_argument("--include", dest="inc_dirs", action='append', type=str, help="Directories where to look for include files")
    parser.add_argument('--outdir', dest='outdir', action='store', default='.', help='Output directory where files will be copied')
    parser.add_argument('sources', metavar='FILE', nargs='+', type=str, help='List of RTL file paths')
    return parser


def main():
    parser = make_parser()
    args = parser.parse_args()

    # Check if slang is available
    slang = shutil.which('slang')
    if slang is None:
        print("Error: 'slang' executable not found", file=sys.stderr)
        sys.exit(1)

    # Initialize inc_dirs if not defined
    if args.inc_dirs is None:
        args.inc_dirs = []    
    
    # Set common slang arguments
    top_module = ('--top', args.top_module) if args.top_module is not None else ()
    synthesis = ('-DSYNTHESIS',) if args.synthesis else ()

    # Create the output directory
    os.makedirs(args.outdir, exist_ok=True)
    output_file = os.path.join(args.outdir, 'rtl_sources.f')
    
    slang_base_args = [
        slang,
        '--depfile-trim', '--Mall', output_file,
        *top_module,
        *synthesis,
        *['-I' + ','.join(args.inc_dirs)],        
        *args.sources,
    ]

    # Get the used files list from slang
    try:
        subprocess.run([*slang_base_args], capture_output=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Fatal: error({e.returncode}): {e.stderr.decode('utf-8', errors='replace')}", file=sys.stderr)
        raise

if __name__ == "__main__":
    main()
