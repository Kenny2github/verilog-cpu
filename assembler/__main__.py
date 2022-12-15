import sys
from itertools import chain
import argparse
from .assemble import mkbytes

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='cmd', required=True)
hex_parser = subparsers.add_parser('to_hex')
hex_parser.add_argument('infile', default='-')
hex_parser.add_argument('outfile', default='-')

def to_hex(infile: str, outfile: str) -> None:
    if infile == '-':
        text = sys.stdin.read()
    else:
        with open(infile, 'r') as f:
            text = f.read()
    if outfile == '-':
        out = sys.stdout
    else:
        out = open(outfile, 'w')
    data = mkbytes(text)
    wordsperline = 25
    print(f"""
// memory data file (do not edit the following line - required for mem load use)
// instance=/cpu/u_datapath/u_MEM0/altsyncram_component/m_default/altsyncram_inst/mem_data
// format=hex addressradix=h dataradix=h version=1.0 wordsperline={wordsperline}
""".strip(), file=out)
    remainder = len(data) % wordsperline
    rows = chain(zip(*[iter(data)]*wordsperline), [data[-remainder:]])
    for addr, row in enumerate(rows):
        if not row:
            continue
        addr = f'@{addr * wordsperline:x}'.rjust(3)
        row = ' '.join(f'{byte:02x}' for byte in row)
        print(f'{addr} {row}', file=out)
    if outfile != '-':
        out.close()

args = parser.parse_args()

if args.cmd == 'to_hex':
    to_hex(args.infile, args.outfile)
