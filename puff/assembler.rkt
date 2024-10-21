#lang racket

(require "utils.rkt")

#|
  This module provides a simple assembler for Ethereum Virtual Machine (EVM) opcodes.
  It provides a mapping from opcode names to their hexadecimal values, and functions
  to convert between opcode names and their hexadecimal values.

  The module also provides functions to convert between bytes and hexadecimal strings.
|#

(define opcode-map
  (hash "STOP" #x00
        "ADD" #x01
        "MUL" #x02
        "SUB" #x03
        "DIV" #x04
        "SDIV" #x05
        "MOD" #x06
        "SMOD" #x07
        "ADDMOD" #x08
        "MULMOD" #x09
        "EXP" #x0a
        "SIGNEXTEND" #x0b
        "LT" #x10
        "GT" #x11
        "SLT" #x12
        "SGT" #x13
        "EQ" #x14
        "ISZERO" #x15
        "AND" #x16
        "OR" #x17
        "XOR" #x18
        "NOT" #x19
        "BYTE" #x1a
        "SHL" #x1b
        "SHR" #x1c
        "SAR" #x1d
        "KECCAK256" #x20
        "ADDRESS" #x30
        "BALANCE" #x31
        "ORIGIN" #x32
        "CALLER" #x33
        "CALLVALUE" #x34
        "CALLDATALOAD" #x35
        "CALLDATASIZE" #x36
        "CALLDATACOPY" #x37
        "CODESIZE" #x38
        "CODECOPY" #x39
        "GASPRICE" #x3a
        "EXTCODESIZE" #x3b
        "EXTCODECOPY" #x3c
        "RETURNDATASIZE" #x3d
        "RETURNDATACOPY" #x3e
        "EXTCODEHASH" #x3f
        "BLOCKHASH" #x40
        "COINBASE" #x41
        "TIMESTAMP" #x42
        "NUMBER" #x43
        "PREVRANDAO" #x44
        "GASLIMIT" #x45
        "CHAINID" #x46
        "SELFBALANCE" #x47
        "BASEFEE" #x48
        "BLOBHASH" #x49
        "BLOBBASEFEE" #x4a
        "POP" #x50
        "MLOAD" #x51
        "MSTORE" #x52
        "MSTORE8" #x53
        "SLOAD" #x54
        "SSTORE" #x55
        "JUMP" #x56
        "JUMPI" #x57
        "PC" #x58
        "MSIZE" #x59
        "GAS" #x5a
        "JUMPDEST" #x5b
        "TLOAD" #x5C
        "TSTORE" #x5D
        "MCOPY" #x5E
        "PUSH0" #x5F
        "PUSH1" #x60
        "PUSH2" #x61
        "PUSH3" #x62
        "PUSH4" #x63
        "PUSH5" #x64
        "PUSH6" #x65
        "PUSH7" #x66
        "PUSH8" #x67
        "PUSH9" #x68
        "PUSH10" #x69
        "PUSH11" #x6A
        "PUSH12" #x6B
        "PUSH13" #x6C
        "PUSH14" #x6D
        "PUSH15" #x6E
        "PUSH16" #x6F
        "PUSH17" #x70
        "PUSH18" #x71
        "PUSH19" #x72
        "PUSH20" #x73
        "PUSH21" #x74
        "PUSH22" #x75
        "PUSH23" #x76
        "PUSH24" #x77
        "PUSH25" #x78
        "PUSH26" #x79
        "PUSH27" #x7A
        "PUSH28" #x7B
        "PUSH29" #x7C
        "PUSH30" #x7D
        "PUSH31" #x7E
        "PUSH32" #x7F
        "DUP1" #x80
        "DUP2" #x81
        "DUP3" #x82
        "DUP4" #x83
        "DUP5" #x84
        "DUP6" #x85
        "DUP7" #x86
        "DUP8" #x87
        "DUP9" #x88
        "DUP10" #x89
        "DUP11" #x8A
        "DUP12" #x8B
        "DUP13" #x8C
        "DUP14" #x8D
        "DUP15" #x8E
        "DUP16" #x8F
        "SWAP1" #x90
        "SWAP2" #x91
        "SWAP3" #x92
        "SWAP4" #x93
        "SWAP5" #x94
        "SWAP6" #x95
        "SWAP7" #x96
        "SWAP8" #x97
        "SWAP9" #x98
        "SWAP10" #x99
        "SWAP11" #x9A
        "SWAP12" #x9B
        "SWAP13" #x9C
        "SWAP14" #x9D
        "SWAP15" #x9E
        "SWAP16" #x9F
        "LOG0" #xA0
        "LOG1" #xA1
        "LOG2" #xA2
        "LOG3" #xA3
        "LOG4" #xA4
        "CREATE" #xF0
        "CALL" #xF1
        "CALLCODE" #xF2
        "RETURN" #xF3
        "DELEGATECALL" #xF4
        "CREATE2" #xF5
        "STATICCALL" #xFA
        "REVERT" #xFD
        "INVALID" #xFE
        "SELFDESTRUCT" #xFF))

(define opcodes (hash-keys opcode-map))

(define (byte->opcode)
  (let ([byte (read-byte)])
    (hash-ref opcode-map byte)))

(define (assemble-opcode opcode)
  (cond
    [(hash-has-key? opcode-map opcode) (byte->hex (hash-ref opcode-map opcode))]
    [(string-prefix? opcode "0x") (substring opcode 2)]
    [else (error "Unknown opcode" opcode)]))

(define (assemble-opcodes opcodes)
  (map assemble-opcode opcodes))

(provide opcode-map opcodes assemble-opcode assemble-opcodes)
