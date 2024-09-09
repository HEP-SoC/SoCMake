import argparse
import shutil
import subprocess
import os

def make_parser():
    parser = argparse.ArgumentParser(description="Filter RTL files based on module hierarchy.")
    parser.add_argument("--top-module", dest="top_module", action="store", default=None, help="Specify top module name")
    parser.add_argument("--skiplist", dest="skiplist", action="store", default=None, help="Optional list of modules to skip")
    parser.add_argument("--deps_dir", dest="deps_dir", action="store", default="", help="Base directory of the dependencies")
    parser.add_argument("--include", dest="inc_dirs", action='append', type=str, help="Directories where to look for include files")
    parser.add_argument('--outdir', dest='outdir', action='store', default='.', help='Output directory where files will be copied')
    parser.add_argument('sources', metavar='FILE', nargs='+', type=str, help='List of RTL file paths')
    return parser


def main():
    parser = make_parser()
    args = parser.parse_args()

    # Check if vhier is available
    try:
        vhier = shutil.which('vhier')
        if vhier is None:
            raise FileNotFoundError
    except FileNotFoundError:
        print('Error: "vhier" executable not found')

    # Initialize the output list with all the packages,
    # because they're not retained by vhier
    output_src = [f for f in args.sources if "_pkg" in f]

    # Set common vhier arguments
    top_module = ('--top-module', args.top_module) if args.top_module is not None else ()
    skiplist = ('--skiplist', args.skiplist) if args.skiplist is not None else ()
    vhier_base_args = [
        vhier,
        '--no-missing',
        *top_module,
        *skiplist,
        *[f'+incdir+{i}' for i in args.inc_dirs],
        *args.sources,
    ]

    # Get the used files list from vhier
    try:
        cells_output = subprocess.run([*vhier_base_args, '--cells'], capture_output=True, check=True)
    except subprocess.CalledProcessError as e:
        print("Fatal: ", e.returncode, e.stderr)
        raise

    output_src.extend(sorted(set([f.decode() for f in cells_output.stdout.split()])))

    # Copy files to output directory
    copied_src = []
    for i in output_src:
        dest_dir = os.path.join(args.outdir, i.replace(args.deps_dir, '').split('/')[1].rsplit('-', 1)[0])
        os.makedirs(dest_dir, exist_ok=True)
        copied_src.append(shutil.copy2(i, dest_dir))

    # Write copied files list to outdir
    with open(os.path.join(args.outdir, 'rtl_sources.f'), 'w') as outfile:
        for i in copied_src:
            outfile.write(f'{i}\n')

    # Get the includes list from vhier
    try:
        includes_output = subprocess.run([*vhier_base_args, '--includes'], capture_output=True, check=True)
    except subprocess.CalledProcessError as e:
        print("Fatal: ", e.returncode, e.stderr)
        raise

    output_inc = sorted(set([f.decode() for f in includes_output.stdout.split()]))

    # Copy the include files in a include folder
    dest_dir = os.path.join(args.outdir, 'include')
    os.makedirs(dest_dir, exist_ok=True)
    for i in output_inc:
        shutil.copy2(i, dest_dir)

if __name__ == "__main__":
    main()
