import argparse
from re import split
# import xml.etree.ElementTree as ET
# import lxml.etree.ElementTree as ET
from lxml import etree as ET
import os, re
from collections import defaultdict
import jinja2

def path_to_module(node):
    if node.tag == 'module':
        return [node]

    # path.append(node)
    # if node.tag == 'begin':
    #     if node.get('name') is not None:
    #         path.extend(node)
    path =  path_to_module(node.getparent())
    path.append(node)
    return path
    # return path
    # else:
    #     if parent.tag == 'begin':
    #         if parent.get('name') is not None:


def append_reg(regs_d : dict, reg_varref, module, attrib='name'):
    path = path_to_module(reg_varref)
    str_path = ""
    for p in path:
        if p.tag == 'module':
            str_path += p.get('name') 

        if p.tag == 'begin':
            if p.get('name') is not None:
                str_path += "." + p.get('name')
        if p.tag == 'varref':
            str_path += "." + p.get('name')

    try:
        if reg_varref.get('name') not in regs_d[module.get(attrib)]:
            regs_d[module.get(attrib)].append(reg_varref.get('name'))
    except KeyError:
        regs_d[module.get(attrib)] = [reg_varref.get('name')]

    return regs_d

def get_reg_recursive(node):
    if node.tag == "varref":
        return node
    elif node.tag == "arraysel" or node.tag == "sel" or node.tag == "structsel":
        return get_reg_recursive(node[0])

    assert False, f"Unexpected {node.tag}, only supported is varref, arraysel, sel for now, review the script to add suport for {node.tag} on left hand side of non blocking assignment"

def process_h_tmpl(context : dict) -> str:

    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader('%s/' % os.path.dirname(__file__)),
        trim_blocks=True,
        lstrip_blocks=True)

    res = env.get_template("seq_vpi_handles.j2").render(context)
    return res


def main(
        xml_file : str,
        outdir : str,
        prefix : str | None,
        vlt : bool,
        reg_list : bool,
        reg_h : bool,
        ):
    tree = ET.parse(xml_file)
    root = tree.getroot()

    # root = modify_path_to_generate_blocks(root)
    # get reg names
    regs = {}
    regs_origname = {}
    for module in root.findall('.//module'):
        for assigndly in module.findall('.//assigndly'):
            lhs = assigndly[1]
            reg = get_reg_recursive(lhs)
            regs = append_reg(regs, reg, module)
            regs_origname = append_reg(regs_origname, reg, module, attrib='origName')


    module_paths = {}
    for module in root.findall('.//module'):
        if module.get('name') in regs:
            for cell in root.findall('.//cell'):
                if module.get('name') == cell.get('submodname'):
                    try:
                        if module.get('name') not in module_paths[module.get('name')]:
                            module_paths[module.get('name')].append(cell.get('hier'))
                    except KeyError:
                        module_paths[module.get('name')] = [cell.get('hier')]

    reg_paths = []
    for k,v in module_paths.items():
        for val in v:
            for reg in regs[k]:
                path = val + "." + reg
                path = path.replace('[', '__BRA__')
                path = path.replace(']', '__KET__')
                reg_paths.append(path)
    
    if prefix == None:
        xml_basename = os.path.basename(xml_file)
        prefix = os.path.splitext(xml_basename)[0]

    os.makedirs(outdir, exist_ok=True)

    if vlt:
        outfile = os.path.abspath(os.path.join(outdir, prefix + "_regpublic.vlt"))
        with open(outfile, "w") as f:
            f.write("`verilator_config\n\n")
            for k, v in regs_origname.items():
                for sig in v:
                    sig = sig.split('.')[-1]
                    f.write(f'public_flat_rw -module "{k}" -var "{sig}"\n')
                f.write("\n")

    if reg_list:
        outfile = os.path.abspath(os.path.join(outdir, prefix + "_reglist.txt"))
        with open(outfile, "w") as f:
            for p in reg_paths:
                f.write(f'{p}\n')

    if reg_h:
        outfile = os.path.abspath(os.path.join(outdir, prefix + "_seq_vpi_handles.h"))
        with open(outfile, "w") as f:
            out = process_h_tmpl({'paths' : reg_paths})
            f.write(out)


def modify_path_to_generate_blocks(root):
    blocks = {}
    for begin in root.findall('.//begin'):
        blocks[begin.get('name')] = []

        # print("------------------", begin.attrib)
        for inst in begin.findall('.//instance'):
            blocks[begin.get('name')].append({'loc': inst.get('loc'), 'defName':inst.get('defName')})
        blocks = {key: value for key, value in blocks.items() if value != []}

    key_arrays = defaultdict(list) # Array generate blocks
    keys = {} # Normal generate blocks
    for k, v in blocks.items():
        pattern = r'(\w+)\[(\d+)\]'
        match = re.match(pattern, k)
        if match is not None:
            key_arrays[match[1]].append(v)
        else:
            keys[k] = v

    for k, v in key_arrays.items(): # Verify values are the same for keys list of values
        assert all(x == v[0] for x in v)
        for val in v[0]:
            defname = val['defName']
            loc = val['loc']
            # print(defname)
            cells = root.findall(f".//cell[@submodname='{defname}'][@loc='{loc}']")
            for cnt, cell in enumerate(cells):
                    path = cell.get('hier').split('.')
                    path.insert(-1, k + f"[{cnt}]")
                    path = '.'.join(path)
                    cell.set('hier', path)

    for k, v in keys.items():
        for val in v:
            for cell in root.findall('.//cell'):
                if cell.get('submodname') == val['defName'] and cell.get('loc') == val['loc']:
                    path = cell.get('hier').split('.')
                    path.insert(-1, k)
                    path = '.'.join(path)
                    cell.set('hier', path)
    return root

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
            prog='Verilator sequential nets XML parser',
            description='Parses Verilator XML file generated with --xml-only command line option, and finds all the non blocking assignment left hand side nets. Generates multiple formats from the list: .vlt for verilator public, ...')

    parser.add_argument('xmlfile', help='XML input file')
    parser.add_argument('outdir', help='Generated files output dir')
    parser.add_argument('--prefix', type=str, help='Prefix of the output files <prefix>_regpublic.vlt')

    parser.add_argument('--vlt', action="store_true", help='Generate vlt verilator config file')
    parser.add_argument('--reg-list', action="store_true", help='Generate file with list of register paths')
    parser.add_argument('--reg-h', action="store_true", help='Generate file with list of register paths')

    args = parser.parse_args()
    main(args.xmlfile, args.outdir, args.prefix, args.vlt, args.reg_list, args.reg_h)





