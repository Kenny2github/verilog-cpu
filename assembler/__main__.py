import sys
from itertools import chain
import argparse
from .assemble import mkbytes

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='cmd', required=True)
hex_parser = subparsers.add_parser('to_hex')

def to_hex():
    text = sys.stdin.read()
    data = mkbytes(text)
    wordsperline = 25
    print(f"""
// memory data file (do not edit the following line - required for mem load use)
// instance=/cpu/u_datapath/u_MEM0/altsyncram_component/m_default/altsyncram_inst/mem_data
// format=hex addressradix=h dataradix=h version=1.0 wordsperline={wordsperline}
""".strip())
    remainder = len(data) % wordsperline
    rows = chain(zip(*[iter(data)]*wordsperline), [data[-remainder:]])
    for addr, row in enumerate(rows):
        addr = f'@{addr * wordsperline:x}'.rjust(3)
        row = ' '.join(f'{byte:02x}' for byte in row)
        print(f'{addr} {row}')

args = parser.parse_args()

if args.cmd == 'to_hex':
    to_hex()
