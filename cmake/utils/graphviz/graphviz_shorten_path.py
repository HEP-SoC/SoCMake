#!/usr/bin/env python3
import sys, getopt
import os
import re

def print_usage():
    print('shorten_path.py -f <dot_file> -o <out_file> -l (remove legend)')
    print('shorten_path.py -h')

def main(in_file, out_file, remove_legend=False):
    f_in = open(in_file, "r")
    f_out = open(out_file, "w")

    # pattern = 'Executable'
    pattern = '(^.*label *= *")(.*?)(".*$)'
    pattern2 = '(^.*//.*-> *)(.*)$'
    for line in f_in:
        result = re.search(pattern, line)
        result2 = re.search(pattern2, line)
        # result = re.match(".*(Executable).*$", line)
        if not result and not result2:
            f_out.write(line)
        elif result:
            res = result.group(2)
            if(os.path.isabs(res)):
                f_out.write(result.group(1) + os.path.basename(res) + result.group(3) + "\n")
            else:
                f_out.write(line)
        elif result2:
            res = result2.group(2)
            if(os.path.isabs(res)):
                f_out.write(result2.group(1) + os.path.basename(res) + "\n")
            else:
                f_out.write(line)

    f_out.close()
    f_in.close()

    if remove_legend:
        pattern_legend = '((.|\n)*)(subgraph *?clusterLegend *?(.|\n)*?})((.|\n)*\Z)'
        f_out = open(out_file, mode = "r")
        whole_file = f_out.read()
        out_text = ""
        # print(whole_file)
        result = re.search(pattern_legend, whole_file)
        if result:
            if(result.lastindex == 5):
                out_text = result.group(1) + result.group(2) + result.group(4) + result.group(5)
            else:
                print("Failed to remove legend from graphviz file")
                out_text = whole_file
        f_out.close()


        f_out = open(out_file, mode = "w")
        f_out.write(out_text)
        f_out.close()


if __name__ == "__main__":
    opts = None
    try:
        opts, args = getopt.getopt(sys.argv[1:],"hlf:o:")
    except getopt.GetoptError:
        print_usage()
    assert opts, "No arguments supplied"

    remove_legend = False
    in_file = None
    out_file = None
    for opt, arg in opts:
        if opt == '-h':
            print_usage()
        elif opt in ("-f"):
            in_file = arg
            in_file = os.path.abspath(in_file)
            assert os.path.isfile(in_file), "File doesnt exist or is not a file"

        elif opt in ("-o"):
            out_file = arg
            out_file = os.path.abspath(out_file)

        elif opt in ("-l"):
            remove_legend = True

    assert in_file, "No in file supplied"
    assert out_file, "No out file supplied"

    main(in_file, out_file, remove_legend)

