import argparse
import tmake

options = argparse.ArgumentParser(description='Systemverilog module stripping')

options.add_argument('-f','--files', nargs='+', help='File(s) to strip', required=True)

for file in options.files:
    print(file)
