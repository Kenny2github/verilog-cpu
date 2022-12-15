from typing_extensions import assert_never
from .lexer import *

INST_LENGTHS = {
    HALT: 1,
    NOOP: 1,
    WRIM: 2,
    JUMP: 2,
    MATH: 2,
    Load: 3,
    Store: 3,
    JINZ: 2,
    JIEQ: 2,
    JILT: 2,
    JIGT: 2,
    SHOM: 2,
}

SINGLE_ADDR_INSTS = {
    WRIM: 0x02,
    JUMP: 0x03,
    JINZ: 0x0a,
    JIEQ: 0x0b,
    JILT: 0x0c,
    JIGT: 0x0d,
    SHOM: 0x0e,
}

REGISTER_CODES = {
    'reg0': 0x00,
    'reg1': 0x01,
    'reg2': 0x02,
    'reg3': 0x03,
    'reg4': 0x04,
    'reg5': 0x05,
    'reg6': 0x06,
    'reg7': 0x07,
    'rax': 0x08,
    'rip': 0x09,
    'rfl': 0x0a,
}

MATH_OPS = {
    'ADD': 0x00,
    'SUB': 0x01,
    'MUL': 0x02,
    'DIV': 0x03,
    'MOD': 0x04,
    'IOR': 0x05,
    'AND': 0x06,
    'XOR': 0x07,
    'NOR': 0x08,
    'NAND': 0x09,
    'XNOR': 0x0a,
    'NOT': 0x0b,
    'NEG': 0x0c,
    'LSHIFT': 0x0d,
    'RSHIFT': 0x0e,
    'LIOR': 0x0f,
    'LAND': 0x10,
    'LXOR': 0x11,
    'LNOR': 0x12,
    'LNAND': 0x13,
    'LXNOR': 0x14,
    'LNOT': 0x15,
    'UIOR': 0x16,
    'NZERO': 0x16,
    'UAND': 0x17,
    'ONES': 0x17,
    'UXOR': 0x18,
    'PARITY': 0x18,
    'CMP': 0x7f,
}

def resolve_addr(addr: MemAddr, labels: dict[str, int]) -> int:
    if isinstance(addr, Label):
        return labels[addr.name]
    if isinstance(addr, str): # number
        return int(addr, 0)
    if isinstance(addr, Product):
        arg1 = resolve_addr(addr.arg1, labels)
        return arg1 * resolve_addr(addr.arg2, labels)
    if isinstance(addr, Additive):
        arg1 = resolve_addr(addr.arg1, labels)
        if addr.op == '+':
            return arg1 + resolve_addr(addr.arg2, labels)
        if addr.op == '-':
            return arg1 - resolve_addr(addr.arg2, labels)
        assert_never(addr.op)
    if isinstance(addr, Parenthesized):
        return resolve_addr(addr.value, labels)
    assert_never(addr)

def mkbytes(text: str) -> bytes:
    assembly = parse(text)
    # find label name to memaddr mapping
    labels: dict[str, int] = {}
    addr: int = 0
    for item in assembly.instructions:
        if isinstance(item, Label):
            labels[item.name] = addr
            continue
        if isinstance(item, Data):
            # these can appear anywhere, and explicitly specify address,
            # so we ignore them when finding label addresses
            continue
        addr += INST_LENGTHS[type(item)]
    # generate instruction data
    memory = bytearray(256)
    addr = 0
    for item in assembly.instructions:
        if isinstance(item, Label):
            continue # we can ignore these now
        if isinstance(item, Data):
            addr_arg = resolve_addr(item.addr, labels)
            data = bytes(int(byte, 0) for byte in item.bytes)
            memory[addr_arg:addr_arg + len(data)] = data
            continue
        elif isinstance(item, HALT):
            data = bytes([0x00])
        elif isinstance(item, NOOP):
            data = bytes([0x01])
        elif isinstance(item, (
            WRIM,
            JUMP,
            JINZ,
            JIEQ,
            JILT,
            JIGT,
            SHOM,
        )):
            addr_arg = resolve_addr(item.addr, labels)
            data = bytes([SINGLE_ADDR_INSTS[type(item)], addr_arg])
        elif isinstance(item, MATH):
            data = bytes([0x04, MATH_OPS[item.op.op]])
        elif isinstance(item, Load):
            item = item.inst
            # don't actually have to care about which mnemonic was used
            # the type of the argument will take care of that for us
            reg_code = REGISTER_CODES[item.reg.name]
            if isinstance(item.arg, Immediate):
                inst = 0x06 # LDFI
                arg = int(item.arg.value, 0)
            elif isinstance(item.arg, RegMem):
                inst = 0x07 # LDFR
                arg = REGISTER_CODES[item.arg.reg.name]
            elif isinstance(item.arg, ROReg):
                inst = 0x08 # CPFR
                arg = REGISTER_CODES[item.arg.name]
            else:
                inst = 0x05 # LDFM
                arg = resolve_addr(item.arg.addr, labels)
            data = bytes([inst, reg_code, arg])
        elif isinstance(item, Store):
            item = item.inst
            reg_code = REGISTER_CODES[item.reg.name]
            addr_arg = resolve_addr(item.arg, labels)
            data = bytes([0x09, reg_code, addr_arg])
        else:
            assert_never(item)
        memory[addr:addr + len(data)] = data
        addr += len(data)
    return bytes(memory)
