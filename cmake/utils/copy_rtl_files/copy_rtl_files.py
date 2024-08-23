import os
import shutil
import argparse
from tmrg.verilog_elaborator import VerilogElaborator

def remove_common_path(file_paths):
    # Find the common path
    common_path = os.path.commonpath(file_paths)

    # Get the last common directory
    last_common_directory = os.path.basename(common_path)

    # Iterate over each file path and remove the common path
    updated_paths = []
    for path in file_paths:
        relative_path = os.path.relpath(path, common_path)
        updated_path = os.path.join(last_common_directory, relative_path)
        updated_paths.append(updated_path)

    return updated_paths

def parse_input_files(velab, input_files):

    def _enterH(velab, module, i="", done=[], hierarchy_files=[], hierarchy_missing_files=[]):
        i += "  |"
        for instName, inst in velab.global_namespace.modules[module].instances:
            if inst.module_name in velab.global_namespace.modules:
                print(i+"- "+instName+":"+inst.module_name)
                hierarchy_files.append(velab.global_namespace.modules[inst.module_name].file.filename)
                if id(inst) in done:
                    continue
                else:
                    done.append(id(inst))
                    _enterH(velab, inst.module_name, i, done, hierarchy_files, hierarchy_missing_files)
            else:
                print(i+"- [!] "+instName+":"+inst.module_name)
                if inst.module_name not in hierarchy_missing_files:
                    hierarchy_missing_files.append(inst.module_name)

    done = []
    hierarchy_files = []
    hierarchy_missing_files = []
    _enterH(velab, velab.topModule, "", done, hierarchy_files, hierarchy_missing_files)

    # for module in hierarchy_files:
    #     print(f"Module {module} found")

    for module in hierarchy_missing_files:
        print(f"WARNING: Module {module} missing")

    return hierarchy_files


def main():
    parser = argparse.ArgumentParser(description="Filter RTL files based on module hierarchy.")
    # parser.add_argument('--top', help='Top module name')
    parser.add_argument('--outdir', help='Output directory where files will be copied')
    parser.add_argument('--list-files', action="store_true", help="Don't generate files, but instead just list the files that will be generated")
    parser.add_argument("--inc-dir", dest="inc_dir", action="append", default=[],
                        help="Directory where to look for include files (use option --include to actualy include the files during preprocessing)")
    parser.add_argument("--include", dest="include",
                        action="store_true", default=False, help="Include include files")
    parser.add_argument("--generate-report", dest="generateBugReport",
                        action="store_true", default=False, help="Generate bug report")
    parser.add_argument("--stats", dest="stats", action="store_true", help="Print statistics")
    parser.add_argument("--top-module", dest="top_module", action="store", default="", help="Specify top module name")
    parser.add_argument('files', metavar='F', type=str, nargs='+', help='List of RTL file paths')

    args = parser.parse_args()

    try:
        files = [f for f in args.files if not "_pkg" in f]

        # We manually add some attributes to be compliant with the expected options
        args.libs = []
        # We use TMRG libraries to elaborate our design
        velab = VerilogElaborator(args, files, "tmrg")
        # First files have to be parsed
        velab.parse()
        # Then the design can be elaborated
        velab.elaborate(allowMissingModules=True)
        # Get on the files from the hierarchy if top module is provided
        if args.top_module:
            files = parse_input_files(velab, files)


        # Remove common path of the files
        files_striped = remove_common_path(files)
        # Get absolute path of the dst directory
        abs_path = os.path.abspath(args.outdir)
        # Change file paths to dst directory
        files_dst = []
        for f_dst in files_striped:
            files_dst.append(abs_path + '/' + f_dst)

        # Only print the files if argument is passed
        if args.list_files:
            print(*files_dst)
        else:
            file_list_path = abs_path + '/file_list.txt'
            # Check if the file list exist, otherwise create it
            os.makedirs(os.path.dirname(file_list_path), exist_ok=True)
            # Write the files to the file list
            with open(file_list_path, 'w') as outfile:
                for f_src, f_dst in zip(files, files_dst):
                    # Write the path to the list of path file
                    outfile.write(f_dst + '\n')
                    # Create the folder hierarchy
                    os.makedirs(os.path.dirname(f_dst), exist_ok=True)
                    # Copy the file to the new location
                    shutil.copy2(f_src, f_dst)

                # Add empty line at the end of the file
                outfile.write('\n')
            print(f"Filtered file list written to {file_list_path}")
    except ValueError as e:
        print(e)

if __name__ == "__main__":
    main()
