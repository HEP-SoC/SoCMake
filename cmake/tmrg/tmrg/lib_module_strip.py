import sys
import os
import shutil
import argparse

# Based on tmake: flows/tmrg/tmr/run.py.tpl
# commit: 96449c8a8a5b58ab7583fba04821cb89feda893a
def generate_implementation_lib(fname_in, fname_out):
    """This function loads a post-implementation netlist and
    generates a simplified version retaining only port information
    of the top module.
    """
    module_name = os.path.splitext(os.path.basename(fname_in))[0]
    _, file_extension = os.path.splitext('/path/to/somefile.ext')
    in_package = False
    in_module = False
    in_module_header = False
    with open(fname_in) as fin, open(fname_out, "w") as fout:
        for line in fin.readlines():
            line_stripped = line.strip()
            # Additional check to skip packages
            if line_stripped.startswith("package %s" % module_name):
                in_package = True
                break
            if line_stripped.startswith("module %s" % module_name):
                in_module_header = True
                in_module = True
            if in_module_header:
                fout.write(line)
                if line_stripped.endswith(");"):
                    in_module_header = False
            elif in_module and file_extension == 'v' and (
                line_stripped.startswith("input ")
                or line_stripped.startswith("inout ")
                or line_stripped.startswith("output ")
            ):
                fout.write(line)
            elif in_module and line_stripped.startswith("endmodule"):
                fout.write(line)
                in_module = False
    # If we have a package file just copy it
    if in_package:
        shutil.copyfile(fname_in, fname_out)

parser = argparse.ArgumentParser(description='Systemverilog module stripping')

parser.add_argument('-f','--files', nargs='+', help='File(s) to strip')
parser.add_argument('-o','--outdir', type=str, help='Output directory where stripped files are generated', required=True)

print('Executing lib_module_strip.py')

options = parser.parse_args()

# Exit if no files are passed
if options.files is None:
    print('No dependencies to strip')
    sys.exit(0)

# Check the output directory exists
outdir = options.outdir
if not os.path.exists(outdir):
    os.makedirs(outdir)

for file in options.files:
    # Take the file basename
    basename = os.path.basename(file)
    stripped_file = f'{outdir}/{basename}'
    generate_implementation_lib(file, stripped_file)
