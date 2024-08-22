import os
import sys
import shutil
import argparse
import re
from tmrg.verilog_elaborator import VerilogElaborator

def find_src_dep_name(file_paths, inc_f = False):
    # Regular expression pattern to match the desired substring
    pattern = r'/([^/]+)-(build|src|subbuild)'

    # Iterate over each file path and remove the common path
    dep_names = []
    for path in file_paths:
        # Search for the pattern in the string
        match = re.search(pattern, path)
        if not match:
            print(f'ERROR : dependency base name for file f{path} not found.')
            sys.exit(1)
        else:
            dep_name = match.group(1)

        # If we have a list of include directories we put the files to includes
        if inc_f:
            # Add the file to the dependencies list
            dep_names.append(f'{dep_name}/includes')
        else:
            last_directory = os.path.basename(os.path.dirname(path))
            # Add the file to the dependencies list
            dep_names.append(f'{dep_name}/{last_directory}/{os.path.basename(path)}')

    return dep_names

def parse_input_files(velab):

    def _enterH(velab, module, i="", done=[], hierarchy_files=[], hierarchy_missing_files=[]):
        i += "  |"
        for instName, inst in velab.global_namespace.modules[module].instances:
            if inst.module_name in velab.global_namespace.modules:
                print(i+"- "+instName+":"+inst.module_name)
                if id(inst) not in done:
                    done.append(id(inst))
                    _enterH(velab, inst.module_name, i, done, hierarchy_files, hierarchy_missing_files)
                # Add the file after so the lowest level modules are first in the list
                module_file_path = velab.global_namespace.modules[inst.module_name].file.filename
                if module_file_path not in hierarchy_files:
                    hierarchy_files.append(module_file_path)
            else:
                print(i+"- [!] "+instName+":"+inst.module_name)
                if inst.module_name not in hierarchy_missing_files:
                    hierarchy_missing_files.append(inst.module_name)

    done = []
    hierarchy_files = []
    hierarchy_missing_files = []
    _enterH(velab, velab.topModule, "", done, hierarchy_files, hierarchy_missing_files)

    # Add the top file to the list
    hierarchy_files.append(velab.global_namespace.modules[velab.topModule].file.filename)

    for module in hierarchy_missing_files:
        print(f"WARNING: Module {module} missing")

    return hierarchy_files

def main():

    parser = argparse.ArgumentParser(description="Filter RTL files based on module hierarchy.")

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
    parser.add_argument('--files', metavar='F', type=str, nargs='+', help='List of RTL file paths')
    parser.add_argument('--inc_dirs', metavar='F', type=str, nargs='+', help='List of RTL include directories')

    args = parser.parse_args()

    try:
        files = args.files

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
            files = parse_input_files(velab)

        # Remove common path of the files
        src_names_list = find_src_dep_name(files)

        # Get the include directories
        inc_dirs = args.inc_dirs
        # Remove common path of the inc_dirs
        inc_names_list = find_src_dep_name(inc_dirs, True)

        # Get absolute path of the dst directory
        abs_path = os.path.abspath(args.outdir)

        # Add absolute path to file destinations
        files_dst = []
        for f_dst in src_names_list:
            files_dst.append(abs_path + '/' + f_dst)
        inc_dirs_dst = []
        for inc_dst in inc_names_list:
            inc_dirs_dst.append(abs_path + '/' + inc_dst)

        # Only print the files if argument is passed
        if args.list_files:
            for f_src, f_dst in zip(files, files_dst):
                print(f"{f_src} \n-> {f_dst}")
            for inc_src, inc_dst in zip(inc_dirs, inc_dirs_dst):
                print(f"{inc_src} \n-> {inc_dst}")
        else:
            file_list_path = abs_path + '/deps_file_list.py'
            # Check if the file list exist, otherwise create it
            os.makedirs(os.path.dirname(file_list_path), exist_ok=True)
            # Write the files to the file list
            with open(file_list_path, 'w') as outfile:
                # Write the rtl files
                outfile.write('rtl_deps_files = [\n')
                for f_src, f_dst in zip(files, files_dst):
                    # Write the path to the list of path file
                    outfile.write(f'  "{f_dst}",\n')
                    # Create the folder hierarchy
                    os.makedirs(os.path.dirname(f_dst), exist_ok=True)
                    # Copy the file to the new location
                    shutil.copy2(f_src, f_dst)
                # Close the rtl_deps_files list
                outfile.write(']\n')
                # Add empty line at the end of the file
                outfile.write('\n')

                # Write the include directories
                any_inc_file_found = False
                for inc_src, inc_dst in zip(inc_dirs, inc_dirs_dst):
                    current_inc_file_found = False
                    # Copy the file to src directory)
                    for inc_file in os.listdir(inc_src):
                        # Only copy files not directories
                        inc_src_abs_path = os.path.join(inc_src, inc_file)
                        inc_dst_abs_path = os.path.join(inc_dst, inc_file)
                        if os.path.isfile(inc_src_abs_path):
                            _, file_ext = os.path.splitext(inc_file)
                            # We only copy files ending with svh
                            if file_ext == '.svh':
                                # Add the list when first inc file is found
                                if not any_inc_file_found:
                                    outfile.write('rtl_deps_incdirs = [\n')
                                    any_inc_file_found = True
                                # Add the path when the first valid inc file is found for the current include directory
                                if not current_inc_file_found:
                                    # Create the folder hierarchy
                                    os.makedirs(os.path.dirname(inc_dst), exist_ok=True)
                                    # Add the include path to the output file
                                    outfile.write(f'  "{inc_src}",\n')
                                    current_inc_file_found = True
                                # Copy the file to the new location
                                shutil.copy2(inc_src_abs_path, inc_dst_abs_path)
                # Close the rtl_deps_incdirs list
                if any_inc_file_found:
                    outfile.write(']\n')
                # Add empty line at the end of the file
                outfile.write('\n')

            print(f"Filtered file list written to {file_list_path}")
    except ValueError as e:
        print(e)

if __name__ == "__main__":
    main()
