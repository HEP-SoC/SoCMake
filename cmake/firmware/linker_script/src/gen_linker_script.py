from typing import List
import sys, os
import jinja2
import argparse

from systemrdl import RDLCompiler, RDLCompileError, RDLListener, RDLWalker
from systemrdl.node import MemNode, Node

class RDL2LdsExporter(RDLListener):
    """Export SystemRDL to Linker Description Script (LDS).

    Class methods:

        - :func:`enter_Mem`
        - :func:`enter_Reg`
        - :func:`isSwEx`
        - :func:`isSwWr`
        - :func:`isBoot`
        - :func:`isStack`
        - :func:`isData`
        - :func:`isBss`
        - :func:`get_sections_prop`
        - :func:`getStackMem`
        - :func:`getProgramMem`
        - :func:`getDataMem`
        - :func:`getBssMem`
        - :func:`getBootMem`
        - :func:`getSwAcc`
        - :func:`write_sections`
        - :func:`export`
        - :func:`process_template``
    """
    def __init__(self):
        self.memories = []
        # SystemRDL registers with the UDP linker_symbol set to true
        # These register adresses are exposed in the linker script
        self.regs = []

    def enter_Mem(self, node):
        if node.get_property("sections", default=False):
            self.memories.append(node)

    def enter_Reg(self, node):
        if node.get_property("linker_symbol", default=False):
            assert not any(reg.inst_name == node.inst_name for reg in self.regs), \
                    f"Only one register with linker_symbol property and the same \
                    instance name can exist, you probably instantiated \
                    {node.parent.orig_type_name} Addrmap multiple times"

            self.regs.append(node)

    def isSwEx(self, mem : MemNode) -> bool:
        """Returns True if the section contains executable code."""
        sections = self.get_sections_prop(mem)
        if "text" in sections:
            return True
        return False

    def isSwWr(self, mem : MemNode) -> bool:
        """Returns True if section is writable by software."""
        sections = self.get_sections_prop(mem)
        if any(item in sections for item in ["data", "bss", "stack"]):
            return True
        return False

    def isBoot(self, mem : MemNode) -> bool:
        """Returns True if section is contains the bootloader."""
        sections = self.get_sections_prop(mem)
        if "boot" in sections:
            return True
        return False

    def isStack(self, mem : MemNode) -> bool:
        """Returns True if section contains the stack."""
        sections = self.get_sections_prop(mem)
        if "stack" in sections:
            return True
        return False

    def isHeap(self, mem : MemNode) -> bool:
        """Returns True if section contains the heap."""
        sections = self.get_sections_prop(mem)
        if "heap" in sections:
            return True
        return False

    def isData(self, mem : MemNode) -> bool:
        """Returns True if section contains data."""
        sections = self.get_sections_prop(mem)
        if "data" in sections:
            return True
        return False

    def isBss(self, mem : MemNode) -> bool:
        """Returns True if section contains the bss (uninitialized global or static variables)."""
        sections = self.get_sections_prop(mem)
        if "bss" in sections:
            return True
        return False

    def get_sections_prop(self, m : MemNode) -> List[str]:
        """Returns a list of string corresponding to the section properties."""
        sections = m.get_property('sections').split('|')
        for s in sections:
            assert_m = f"Illegal property for sections: {s} of memory: {m.inst_name} in addrmap: {m.parent.inst_name}"
            assert s in ['text', 'data', 'bss', 'boot', 'stack', 'heap'], assert_m

        return sections

    def getStackMem(self, mems: List[MemNode]) -> MemNode:
        stack_mems = []
        for m in mems:
            if self.isStack(m):
                stack_mems.append(m)
        assert len(stack_mems) == 1, f"Exactly 1 memory with section stack is allowed and required {stack_mems}" # TODO

        return stack_mems[0]

    def getHeapMem(self, mems: List[MemNode]) -> MemNode:
        heap_mems = []
        for m in mems:
            if self.isHeap(m):
                heap_mems.append(m)
        assert len(heap_mems) == 1, f"Exactly 1 memory with section heap is allowed and required {heap_mems}" # TODO

        return heap_mems[0]


    def getProgramMem(self, mems: List[MemNode]) -> MemNode:
        """Returns the program/instruction/text MemNode."""
        prog_mems = []
        for m in mems:
            if self.isSwEx(m) and not self.isBoot(m):
                prog_mems.append(m)
        assert len(prog_mems) == 1, f"Exactly 1 memory with program memory is allowed and required {prog_mems}" # TODO

        return prog_mems[0]

    def getDataMem(self, mems: List[MemNode]) -> MemNode:
        """Returns the data MemNode."""
        data_mems = []
        for m in mems:
            if self.isData(m):
                data_mems.append(m)
        assert len(data_mems) == 1, f"Exactly 1 memory with program memory is allowed and required {data_mems}" # TODO

        return data_mems[0]

    def getBssMem(self, mems: List[MemNode]) -> MemNode:
        """Returns the bss MemNode."""
        data_mems = []
        for m in mems:
            if self.isData(m):
                data_mems.append(m)
        assert len(data_mems) == 1, f"Exactly 1 memory with program memory is allowed and required {data_mems}" # TODO

        return data_mems[0]

    def getBootMem(self, mems: List[MemNode]) -> "MemNode | None":
        """Returns the boot MemNode."""
        boot_mems = []
        for m in mems:
            if self.isBoot(m):
                boot_mems.append(m)
        assert len(boot_mems) <= 1, f"No more than 1 boot memory is allowed {boot_mems}" # TODO

        return boot_mems[0] if len(boot_mems) > 0 else None

    def getSwAcc(self, mem : MemNode) -> str:
        """Returns the software access rights to the MemNode."""
        out = "r"
        if self.isSwWr(mem):
            out = out + "w"
        if self.isSwEx(mem):
            out = out + "x"
        return out

    def export(self,
               node: Node,
               outfile : str,
               debug : bool = True,
               ):

        context = {'mems'  : self.memories,
                   'debug' : debug,
                   'regs'  : self.regs
                   }

        # text = self.process_template(context, "lds.j2")
        text = self.process_template(context, "linker.lds.j2")

        # assert(node.type_name is not None)
        # out_file = os.path.join(outfile, node.type_name + ".lds")
        with open(outfile, 'w') as f:
            f.write(text)

    def process_template(self, context : dict, template : str) -> str:

        env = jinja2.Environment(
            loader=jinja2.FileSystemLoader('%s/template/' % os.path.dirname(__file__)),
            trim_blocks=True,
            lstrip_blocks=True)

        env.filters.update({
            'zip' : zip,
            'int' : int,
            'isBoot' : self.isBoot,
            'isSwWr' : self.isSwWr,
            'isSwEx' : self.isSwEx,
            'getSwAcc' : self.getSwAcc,
            'getStackMem' : self.getStackMem,
            'getProgramMem' : self.getProgramMem,
            'getBootMem' : self.getBootMem,
            'getDataMem' : self.getDataMem,
            'getBssMem' : self.getBssMem,
            })

        res = env.get_template(template).render(context)
        return res


def main():
    parser = argparse.ArgumentParser(
            prog='LDS generator',
            description='Generates a linker script from RDL files')

    parser.add_argument('--rdlfiles', nargs="+", help='RDL input files')
    parser.add_argument('--outfile', required=True, help='Output lds file')
    parser.add_argument('--debug', default=False, action="store_true", help='Include debug section in the lds or discard it')
    parser.add_argument('-p', '--param', nargs='+', help="Parameter to overwrite on top RDL module in the format 'PARAM=VALUE'")

    args = parser.parse_args()

    overwritten_params_dict = {}
    if args.param is not None:
        for param in args.param:
            key, value = param.split('=')
            overwritten_params_dict[key] = int(value)

    rdlc = RDLCompiler()

    try:
        for input_file in args.rdlfiles:
            rdlc.compile_file(input_file)
        root = rdlc.elaborate(parameters=overwritten_params_dict)
    except RDLCompileError:
        sys.exit(1)

    top_gen = root.children(unroll=True)
    # Is this really needed?
    top = None
    for top in top_gen:
        top = top
    assert top is not None

    walker = RDLWalker(unroll=True)
    rdl2lds = RDL2LdsExporter()
    walker.walk(top, rdl2lds)

    rdl2lds.export(
            node=top,
            outfile=args.outfile,
            debug=args.debug,
            )



if __name__ == "__main__":
    main()

