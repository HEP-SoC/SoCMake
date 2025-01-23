from re import split
from edalize.edatool import get_edatool
import argparse
from typing import List
import sys

def main(
        rtl_files: List[str],
        inc_dirs: List[str],
        verilog_defs : List[str],
        constraint_files: List[str],
        part: str,
        name: str,
        top: str,
        outdir : str,
        ):

    files = []
    for f in rtl_files:
        files.append({'name' : f, 'file_type' : 'verilogSource'})

    for d in inc_dirs:
        files.append({'name' : d, 'file_type' : 'verilogSource', 'is_include_file' : True, 'include_path' : d})

    for f in constraint_files:
        files.append({'name' : f, 'file_type' : 'xdc'})

    params = {}
    params['SYNTHESIS'] = {'datatype' : 'bool', 'default' : True, 'paramtype' : 'vlogdefine'}
    for define in verilog_defs:
        param = define.split('=')
        p_name = param[0]
        type = 'str'
        # Check param list length:
        # len=1: parameter of type MY_DEFINE
        # len=2: parameter of type MY_DEFINE=MYVALUE
        # len>2: error
        param_len = len(param)
        # by default params are set to one if no value is given
        param_value = '1'
        if (param_len == 1):
            print(f"edalize_vivado.py - Warning: define {p_name} is assigned the default value of 1")
        elif (param_len == 2):
            param_value = param[1]
        else:
            print(f"edalize_vivado - Fatal error: define {p_name} syntax is wrong: {define}", file=sys.stderr)
        params[p_name] = {'datatype' : type, 'default' : param_value, 'paramtype' : 'vlogdefine'}

    tool = 'vivado'

    edam = {
            'files'        : files,
            'name'         : name,
            'parameters'   : params,
            'toplevel'     : top,
            'tool_options' : {tool : {'part' : part}},
            }

    backend = get_edatool(tool)(edam=edam, work_root=outdir)

    backend.configure()
    backend.build()
    backend.run()



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process RTL files with constraints')

    parser.add_argument('--rtl-files', nargs='+', type=str, help='List of RTL files')
    parser.add_argument('--verilog-defs', nargs='*', type=str, help='List of Verilog defines <NAME>=VALUE')
    parser.add_argument('--inc-dirs', nargs='*', type=str, help='List of RTL inc_dirs')
    parser.add_argument('--constraint-files', nargs='+', type=str, help='List of constraint files')
    parser.add_argument('--part', type=str, help='Single string specifying the part')
    parser.add_argument('--name', type=str, help='Single string specifying the name')
    parser.add_argument('--top', type=str, help='Single string specifying the top')
    parser.add_argument('--outdir', type=str, help='Build directory')

    args = parser.parse_args()

    main(
        rtl_files=args.rtl_files,
        inc_dirs=args.inc_dirs,
        verilog_defs=args.verilog_defs,
        constraint_files=args.constraint_files,
        part=args.part,
        name=args.name,
        top=args.top,
        outdir=args.outdir,
    )


