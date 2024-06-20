from jinja2 import Environment, FileSystemLoader
from argparse import ArgumentParser
import os

def init_argparse() -> ArgumentParser:

    parser = ArgumentParser()

    parser.add_argument('-t', '--top', type=str, help='Name of the top', required=True)
    parser.add_argument('-i', '--include', nargs='*', type=str, help='Include directories')
    parser.add_argument('-f', '--files', nargs='*', type=str, help='Source files', required=True)

    return parser

parser = init_argparse()
args = parser.parse_args()

environment = Environment(loader=FileSystemLoader(os.path.dirname(__file__)))
template = environment.get_template('manifest.j2')
content = template.render(
    name = args.top,
    top = args.top,
    rtl_files = args.files
)

with open('manifest', mode='w') as manifest:
    manifest.write(content)