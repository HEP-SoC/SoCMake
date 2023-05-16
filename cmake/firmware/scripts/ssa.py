#!/usr/bin/env python
# Source https://blog.soutade.fr/post/2019/04/max-stack-usage-for-c-program.html

import os
import re
import argparse

class SUInfo:
    def __init__(self, filename, line, func_name, stack_size):
        self.filename = filename
        self.line = line
        self.func_name = func_name
        self.stack_size = stack_size

    def __str__(self):
        s = '%s() <%s:%s> %d' % (self.func_name, self.filename, self.line, self.stack_size)
        return s

class FlowElement:
    def __init__(self, root, depth, stack_size, suinfo):
        self.root = root
        self.depth = depth
        self.stack_size = stack_size
        self.suinfo = suinfo
        self.childs = []

    def append(self, suinfo):
        self.childs.append(suinfo)

    def __str__(self):
        spaces = '    ' * int(self.depth)
        su = self.suinfo
        res = '%s-> %s() %d <%s:%d>' % (spaces, su.func_name, su.stack_size,
                                        su.filename, su.line)
        return res

def display_max_path(element):
    print("======================================================================")
    print("=============== STATIC STACK USAGE AND PATH ANALYSYS =================")
    print("======================================================================\n")
    print('Max stack size %d' % (element.stack_size))
    print('Max path :')
    res = ''
    while element:
        res = str(element) + '\n' + res
        element = element.root
    print(res)
    print("======================================================================\n")

cflow_re = re.compile(r'([ ]*).*\(\) \<.* at (.*)\>[:]?')

def parse_cflow_file(path, su_dict):
    root = None
    cur_root = None
    current = None
    cur_depth = 0
    max_stack_size = 0
    max_path = None
    with open(path) as f:
        while True:
            line = f.readline()
            if not line: break
            match = cflow_re.match(line)
            if not match: continue

            spaces = match.group(1)
            # Convert tab into 4 spaces
            spaces = spaces.replace('\t', '    ')
            depth = len(spaces)/4
            filename = match.group(2)
            (filename, line) = filename.split(':')
            filename = '%s:%s' % (os.path.basename(filename), line)

            suinfo = su_dict.get(filename, None)
            # Some functions may have been inlined
            if not suinfo:
                # print('WARNING: Key %s not found in su dict"' % (filename))
                continue

            if not root:
                root = FlowElement(None, 0, suinfo.stack_size, suinfo)
                cur_root = root
                current = root
                max_path = root
                max_stack_size = suinfo.stack_size
            else:
                # Go back
                if depth < cur_depth:
                    while cur_root.depth > (depth-1):
                        cur_root = cur_root.root
                # Go depth
                elif depth > cur_depth:
                    cur_root = current
                cur_depth = depth
                stack_size = cur_root.stack_size + suinfo.stack_size
                element = FlowElement(cur_root, cur_depth,
                                      stack_size,
                                      suinfo)
                current = element
                if stack_size > max_stack_size:
                    max_stack_size = stack_size
                    max_path = current
                cur_root.append(element)
    display_max_path(max_path)

su_re = re.compile(r'(.*)\t([0-9]+)\t(.*)')

def parse_su_files(path, su_dict):
    for root, dirs, files in os.walk(path):
        for sufile in files:
            if sufile[-2:] != 'su': continue
            with open(os.path.join(path, sufile)) as f:
                while True:
                    line = f.readline()
                    if not line: break
                    match = su_re.match(line)
                    if not match:
                        # print('WARNING no match for "%s"' % (line))
                        continue
                    infos = match.group(1)
                    tmp = infos.split(':')
                    # print(tmp)
                    filename = tmp[0]
                    line = tmp[1]
                    size = tmp[2]
                    function = tmp[3:]

                    # (filename, line, size, function) = infos.split(':')
                    stack_size = int(match.group(2))
                    key = '%s:%s' % (filename, line)
                    su_info = SUInfo(filename, int(line), function, stack_size)
                    su_dict[key] = su_info


if __name__ == '__main__':
    optparser = argparse.ArgumentParser(description='Max static stack size computer')
    optparser.add_argument('-f', '--cflow-file', dest='cflow_file',
                           help='cflow generated file')
    optparser.add_argument('-d', '--su-dir', dest='su_dir',
                           default='.',
                           help='Directory where GNAT .su files are generated')
    options = optparser.parse_args()

    su_dict = {}

    parse_su_files(options.su_dir, su_dict)
    parse_cflow_file(options.cflow_file, su_dict)

