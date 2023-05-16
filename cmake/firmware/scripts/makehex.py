import argparse

def main(binfile : str, outfile : str, width : int):
    with open(binfile, "rb") as f:
        bindata = f.read()

    with open(outfile, "w") as f:
        byte_cnt = 0
        line = ""
        for b in bindata:
            line =  f"{b:02X}" + line # Little endian
            byte_cnt = byte_cnt + 1

            if byte_cnt == width//8:
                f.write(line + "\n");
                line = ""
                byte_cnt = 0

        if line != "":      # If not aligned
            f.write(line + "\n");

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
            prog='Bin to hex file creator',
            description='Generates a hex file from a binary')

    parser.add_argument('binfile', help='Binary input file')
    parser.add_argument('outfile', help='Hex output file')
    parser.add_argument('-w', '--width', type=int, choices=[8,16,32,64], default=32, help='Word with of the processor')

    args = parser.parse_args()

    main(args.binfile, args.outfile, args.width)

