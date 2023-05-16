#!/usr/bin/env python3
from systemrdl import RDLCompiler, RDLCompileError
from peakrdl_html import HTMLExporter
import argparse

from markdown_include.include import MarkdownInclude
import markdown
from typing import List

import sys
import os

def generate(
        rdl_files : List[str], 
        build_dir : str,
        home_url : str,
        ):

    markdown_include = MarkdownInclude(configs={
        'base_path': build_dir,
        'encoding': 'iso-8859-1'
        }
    )
    markdown_inst = markdown.Markdown(
    extensions = [
        'extra',
        'admonition',
        'mdx_math',
        markdown_include,
    ],
    extension_configs={
        'mdx_math':{
            'add_preview': True
        },
        }
    )
#===============================================================================
    rdlc = RDLCompiler()

    try:
        for input_file in rdl_files:
            rdlc.compile_file(input_file)
        root = rdlc.elaborate()
    except RDLCompileError:
        sys.exit(1)

    top_gen = root.children(unroll=True)
    for top in top_gen:
        top = top

    html = HTMLExporter(
            markdown_inst=markdown_inst,
            show_signals=True,
            )
    html.export(
        root,
        build_dir,
        home_url=home_url, # type: ignore
    )

import sys

def main(
        rdlfiles : List[str],
        outdir   : str,
        home_url : str,
        ):
    generate(
            rdl_files=rdlfiles,
            build_dir=outdir,
            home_url=home_url,
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
            prog='Peakrdl-html with markdown',
            description='Generates a html documentation while also embedding the markdown files passed as arguments')

    parser.add_argument('--rdlfiles', nargs="+", help='RDL input files')
    parser.add_argument('--outdir', required=True, help='Generated files output dir')
    parser.add_argument('--home-url', type=str, default="", help='URL of the website for the project')

    args = parser.parse_args()
    main(
        rdlfiles=args.rdlfiles,
        outdir=args.outdir,
        home_url=args.home_url,
        )

