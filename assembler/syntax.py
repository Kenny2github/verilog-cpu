### File generated by parsival v0.0.0a2
# May be modified further as necessary; but these modifications
# will not be preserved if the file is re-generated from a grammar.
from __future__ import annotations
from typing import Literal, Annotated, Union, Optional
from dataclasses import dataclass, InitVar
import parsival
from parsival import Commit
from parsival.helper_rules import *

@dataclass
class Label:
    _item_1: InitVar[Literal[':']]
    _item_2: InitVar[NO_SPACE]
    name: NAME

@dataclass
class Parenthesized:
    _item_1: InitVar[Literal['(']]
    _item_2: InitVar[Commit]
    value: MemAddr
    _item_4: InitVar[Literal[')']]

Number = Union[Regex[str, r"""0x[0-9a-fA-F]+"""], Regex[str, r"""(0d)?[0-9]+"""], Regex[str, r"""0b[01]+"""], Regex[str, r"""0o[0-7]+"""]]

Atom = Union[Number, Parenthesized, Label]

@dataclass
class Product:
    arg1: Product
    op: Literal['*']
    arg2: Atom

@dataclass
class Additive:
    arg1: Additive
    op: Literal['+', '-']
    arg2: Product

MemAddr = Union[Additive, Product, Atom]

_MathOp = Literal['ADD', 'SUB', 'MUL', 'DIV', 'MOD', 'IOR', 'AND', 'XOR', 'NOR', 'NAND', 'XNOR', 'NOT', 'NEG', 'LSHIFT', 'RSHIFT', 'LIOR', 'LAND', 'LXOR', 'LNOR', 'LNAND', 'LXNOR', 'LNOT', 'UIOR', 'NZERO', 'UAND', 'ONES', 'UXOR', 'PARITY', 'CMP']

@dataclass
class MathOp:
    sign: Literal['+', '-']
    _item_2: InitVar[Commit]
    op: _MathOp

@dataclass
class Register:
    _item_1: InitVar[Literal['%']]
    _item_2: InitVar[Commit]
    name: Union[Regex[str, r"""reg[0-7]"""], Literal['rax']]

@dataclass
class ROReg:
    _item_1: InitVar[Literal['%']]
    _item_2: InitVar[Commit]
    name: Union[Regex[str, r"""reg[0-7]"""], Literal['rax'], Literal['rfl'], Literal['rip']]

@dataclass
class RegMem:
    _item_1: InitVar[Literal['[']]
    reg: ROReg
    _item_3: InitVar[Literal[']']]

@dataclass
class Immediate:
    _item_1: InitVar[Literal['$']]
    _item_2: InitVar[Commit]
    _item_3: InitVar[NO_SPACE]
    value: Number

@dataclass
class Dereference:
    _item_1: InitVar[Literal['[']]
    addr: MemAddr
    _item_3: InitVar[Literal[']']]

ReadArg = Union[Immediate, ROReg, RegMem, Dereference]

@dataclass
class SHOM:
    _item_1: InitVar[Literal['show', 'SHOM']]
    addr: MemAddr

@dataclass
class JIGT:
    _item_1: InitVar[Literal['jigt', 'JIGT']]
    addr: MemAddr

@dataclass
class JILT:
    _item_1: InitVar[Literal['jilt', 'JILT']]
    addr: MemAddr

@dataclass
class JIEQ:
    _item_1: InitVar[Literal['jieq', 'JIEQ']]
    addr: MemAddr

@dataclass
class JINZ:
    _item_1: InitVar[Literal['jinz', 'JINZ']]
    addr: MemAddr

@dataclass
class _Store_1:
    mnemonic: Literal['store']
    arg: MemAddr
    _item_3: InitVar[Literal['<-']]
    reg: ROReg

@dataclass
class _Store_2:
    mnemonic: Literal['store']
    reg: ROReg
    _item_3: InitVar[Literal['->']]
    arg: MemAddr

@dataclass
class _Store_3:
    mnemonic: Literal['STOM']
    reg: ROReg
    _item_3: InitVar[Literal['->']]
    arg: MemAddr

_Store = Union[_Store_1, _Store_2, _Store_3]

@dataclass
class Store:
    inst: _Store

@dataclass
class _Load_1:
    mnemonic: Literal['load']
    reg: Register
    _item_3: InitVar[Literal['<-']]
    arg: ReadArg

@dataclass
class _Load_2:
    mnemonic: Literal['load']
    arg: ReadArg
    _item_3: InitVar[Literal['->']]
    reg: Register

@dataclass
class _Load_3:
    mnemonic: Literal['LDFM']
    reg: Register
    _item_3: InitVar[Literal['<-']]
    arg: MemAddr

@dataclass
class _Load_4:
    mnemonic: Literal['LDFI']
    reg: Register
    _item_3: InitVar[Literal['<-']]
    arg: Immediate

@dataclass
class _Load_5:
    mnemonic: Literal['LDFR']
    reg: Register
    _item_3: InitVar[Literal['<-']]
    arg: RegMem

@dataclass
class _Load_6:
    mnemonic: Literal['CPFR']
    reg: Register
    _item_3: InitVar[Literal['<-']]
    arg: ROReg

_Load = Union[_Load_1, _Load_2, _Load_3, _Load_4, _Load_5, _Load_6]

@dataclass
class Load:
    inst: _Load

@dataclass
class MATH:
    _item_1: InitVar[Literal['math', 'MATH']]
    op: MathOp

@dataclass
class JUMP:
    _item_1: InitVar[Literal['jump', 'JUMP']]
    addr: MemAddr

@dataclass
class WRIM:
    _item_1: InitVar[Literal['read', 'WRIM']]
    addr: MemAddr

@dataclass
class NOOP:
    inst: Literal['noop', 'NOOP']

@dataclass
class HALT:
    inst: Literal['halt', 'HALT']

@dataclass
class Data:
    _item_1: InitVar[Literal['data']]
    addr: MemAddr
    _item_3: InitVar[Literal[':']]
    bytes: Annotated[list[Number], "+"]

Instruction = Union[HALT, NOOP, WRIM, JUMP, MATH, Load, Store, JINZ, JIEQ, JILT, JIGT, SHOM]

InstLabel = Union[Instruction, Label, Data]

@dataclass
class Comment:
    _item_1: InitVar[Literal[';']]
    _item_2: InitVar[Commit]
    _item_3: InitVar[Regex[str, r""".*"""]]

@dataclass
class Line_1:
    inst: InstLabel
    _item_2: InitVar[NEWLINE]

@dataclass
class Line_2:
    inst: Optional[InstLabel]
    _item_2: InitVar[Comment]
    _item_3: InitVar[NEWLINE]

Line = Union[Line_1, Line_2]

@dataclass
class Assembly:
    instructions: Annotated[list[Line], "+"]
    _item_2: InitVar[ENDMARKER]

def parse(text: str) -> Assembly:
    '''Parse and return a(n) Assembly.'''
    return parsival.parse(text, Assembly) # type: ignore

if __name__ == '__main__':
    import sys
    import parsival

    text = sys.stdin.read()

    try:
        from prettyprinter import pprint, install_extras
    except ImportError:
        from pprint import pprint
    else:
        install_extras(include=frozenset({'dataclasses'}))

    try:
        parsival.DEBUG = '--debug' in sys.argv
        pprint(parse(text))
    except (SyntaxError, parsival.Failed) as exc:
        print('Failed:', str(exc)[:50], file=sys.stderr)
