#lang racket/base
;;; assembler.rkt - EVM opcode assembly for the Puff compiler
;;;
;;; This module provides a simple assembler for Ethereum Virtual Machine (EVM) opcodes.
;;; It defines the mapping from opcode mnemonics to their hexadecimal byte values,
;;; and provides functions to convert between these representations. The assembler
;;; is the final stage of compilation, translating symbolic opcodes into raw bytecode.

(require "utils.rkt")        ; Utility functions (especially byte->hex)
(require racket/string)      ; String operations

;; opcode-map: hash
;; A comprehensive mapping from EVM opcode mnemonics to their byte values
;; This includes all standard EVM opcodes available in the Ethereum specification
(define opcode-map
  (hash 
   ;; Arithmetic Operations
   "STOP" #x00              ; Halts execution
   "ADD" #x01               ; Addition operation
   "MUL" #x02               ; Multiplication operation
   "SUB" #x03               ; Subtraction operation
   "DIV" #x04               ; Integer division
   "SDIV" #x05              ; Signed integer division
   "MOD" #x06               ; Modulo operation
   "SMOD" #x07              ; Signed modulo operation
   "ADDMOD" #x08            ; Addition with modulo
   "MULMOD" #x09            ; Multiplication with modulo
   "EXP" #x0a               ; Exponential operation
   "SIGNEXTEND" #x0b        ; Sign extension
   
   ;; Comparison & Bitwise Logic
   "LT" #x10                ; Less-than comparison
   "GT" #x11                ; Greater-than comparison
   "SLT" #x12               ; Signed less-than comparison
   "SGT" #x13               ; Signed greater-than comparison
   "EQ" #x14                ; Equality comparison
   "ISZERO" #x15            ; Simple not operator
   "AND" #x16               ; Bitwise AND
   "OR" #x17                ; Bitwise OR
   "XOR" #x18               ; Bitwise XOR
   "NOT" #x19               ; Bitwise NOT
   "BYTE" #x1a              ; Extract a byte from a word
   "SHL" #x1b               ; Shift left
   "SHR" #x1c               ; Logical shift right
   "SAR" #x1d               ; Arithmetic shift right
   
   ;; Cryptographic Operations
   "KECCAK256" #x20         ; Compute Keccak-256 hash
   
   ;; Contract Context Information
   "ADDRESS" #x30           ; Get address of currently executing account
   "BALANCE" #x31           ; Get balance of an account
   "ORIGIN" #x32            ; Get execution origination address
   "CALLER" #x33            ; Get caller address
   "CALLVALUE" #x34         ; Get deposited value by the instruction/transaction
   "CALLDATALOAD" #x35      ; Get input data of current environment
   "CALLDATASIZE" #x36      ; Get size of input data in current environment
   "CALLDATACOPY" #x37      ; Copy input data in current environment to memory
   "CODESIZE" #x38          ; Get size of code running in current environment
   "CODECOPY" #x39          ; Copy code running in current environment to memory
   "GASPRICE" #x3a          ; Get price of gas in current environment
   "EXTCODESIZE" #x3b       ; Get size of an account's code
   "EXTCODECOPY" #x3c       ; Copy an account's code to memory
   "RETURNDATASIZE" #x3d    ; Get size of output data from the previous call
   "RETURNDATACOPY" #x3e    ; Copy output data from the previous call to memory
   "EXTCODEHASH" #x3f       ; Get hash of an account's code
   
   ;; Block Information
   "BLOCKHASH" #x40         ; Get the hash of one of the 256 most recent complete blocks
   "COINBASE" #x41          ; Get the block's beneficiary address
   "TIMESTAMP" #x42         ; Get the block's timestamp
   "NUMBER" #x43            ; Get the block's number
   "PREVRANDAO" #x44        ; Get random value from beacon chain (formerly difficulty)
   "GASLIMIT" #x45          ; Get the block's gas limit
   "CHAINID" #x46           ; Get the chain ID
   "SELFBALANCE" #x47       ; Get balance of currently executing account
   "BASEFEE" #x48           ; Get the base fee
   "BLOBHASH" #x49          ; Get a blob commitment hash
   "BLOBBASEFEE" #x4a       ; Get blob fee
   
   ;; Stack, Memory, Storage and Flow Operations
   "POP" #x50               ; Remove item from stack
   "MLOAD" #x51             ; Load word from memory
   "MSTORE" #x52            ; Save word to memory
   "MSTORE8" #x53           ; Save byte to memory
   "SLOAD" #x54             ; Load word from storage
   "SSTORE" #x55            ; Save word to storage
   "JUMP" #x56              ; Alter the program counter
   "JUMPI" #x57             ; Conditionally alter the program counter
   "PC" #x58                ; Get the program counter
   "MSIZE" #x59             ; Get the size of active memory
   "GAS" #x5a               ; Get the amount of available gas
   "JUMPDEST" #x5b          ; Mark a valid jump destination
   "TLOAD" #x5C             ; Load from transient storage
   "TSTORE" #x5D            ; Save to transient storage
   "MCOPY" #x5E             ; Memory copy operation
   
   ;; Push Operations (for constants)
   "PUSH0" #x5F             ; Place 0 on stack
   "PUSH1" #x60             ; Place 1-byte item on stack
   "PUSH2" #x61             ; Place 2-byte item on stack
   "PUSH3" #x62             ; Place 3-byte item on stack
   "PUSH4" #x63             ; Place 4-byte item on stack
   "PUSH5" #x64             ; Place 5-byte item on stack
   "PUSH6" #x65             ; Place 6-byte item on stack
   "PUSH7" #x66             ; Place 7-byte item on stack
   "PUSH8" #x67             ; Place 8-byte item on stack
   "PUSH9" #x68             ; Place 9-byte item on stack
   "PUSH10" #x69            ; Place 10-byte item on stack
   "PUSH11" #x6A            ; Place 11-byte item on stack
   "PUSH12" #x6B            ; Place 12-byte item on stack
   "PUSH13" #x6C            ; Place 13-byte item on stack
   "PUSH14" #x6D            ; Place 14-byte item on stack
   "PUSH15" #x6E            ; Place 15-byte item on stack
   "PUSH16" #x6F            ; Place 16-byte item on stack
   "PUSH17" #x70            ; Place 17-byte item on stack
   "PUSH18" #x71            ; Place 18-byte item on stack
   "PUSH19" #x72            ; Place 19-byte item on stack
   "PUSH20" #x73            ; Place 20-byte item on stack
   "PUSH21" #x74            ; Place 21-byte item on stack
   "PUSH22" #x75            ; Place 22-byte item on stack
   "PUSH23" #x76            ; Place 23-byte item on stack
   "PUSH24" #x77            ; Place 24-byte item on stack
   "PUSH25" #x78            ; Place 25-byte item on stack
   "PUSH26" #x79            ; Place 26-byte item on stack
   "PUSH27" #x7A            ; Place 27-byte item on stack
   "PUSH28" #x7B            ; Place 28-byte item on stack
   "PUSH29" #x7C            ; Place 29-byte item on stack
   "PUSH30" #x7D            ; Place 30-byte item on stack
   "PUSH31" #x7E            ; Place 31-byte item on stack
   "PUSH32" #x7F            ; Place 32-byte item on stack
   
   ;; Duplication Operations
   "DUP1" #x80              ; Duplicate 1st stack item
   "DUP2" #x81              ; Duplicate 2nd stack item
   "DUP3" #x82              ; Duplicate 3rd stack item
   "DUP4" #x83              ; Duplicate 4th stack item
   "DUP5" #x84              ; Duplicate 5th stack item
   "DUP6" #x85              ; Duplicate 6th stack item
   "DUP7" #x86              ; Duplicate 7th stack item
   "DUP8" #x87              ; Duplicate 8th stack item
   "DUP9" #x88              ; Duplicate 9th stack item
   "DUP10" #x89             ; Duplicate 10th stack item
   "DUP11" #x8A             ; Duplicate 11th stack item
   "DUP12" #x8B             ; Duplicate 12th stack item
   "DUP13" #x8C             ; Duplicate 13th stack item
   "DUP14" #x8D             ; Duplicate 14th stack item
   "DUP15" #x8E             ; Duplicate 15th stack item
   "DUP16" #x8F             ; Duplicate 16th stack item
   
   ;; Exchange Operations
   "SWAP1" #x90             ; Exchange 1st and 2nd stack items
   "SWAP2" #x91             ; Exchange 1st and 3rd stack items
   "SWAP3" #x92             ; Exchange 1st and 4th stack items
   "SWAP4" #x93             ; Exchange 1st and 5th stack items
   "SWAP5" #x94             ; Exchange 1st and 6th stack items
   "SWAP6" #x95             ; Exchange 1st and 7th stack items
   "SWAP7" #x96             ; Exchange 1st and 8th stack items
   "SWAP8" #x97             ; Exchange 1st and 9th stack items
   "SWAP9" #x98             ; Exchange 1st and 10th stack items
   "SWAP10" #x99            ; Exchange 1st and 11th stack items
   "SWAP11" #x9A            ; Exchange 1st and 12th stack items
   "SWAP12" #x9B            ; Exchange 1st and 13th stack items
   "SWAP13" #x9C            ; Exchange 1st and 14th stack items
   "SWAP14" #x9D            ; Exchange 1st and 15th stack items
   "SWAP15" #x9E            ; Exchange 1st and 16th stack items
   "SWAP16" #x9F            ; Exchange 1st and 17th stack items
   
   ;; Logging Operations
   "LOG0" #xA0              ; Append log record (no topics)
   "LOG1" #xA1              ; Append log record (1 topic)
   "LOG2" #xA2              ; Append log record (2 topics)
   "LOG3" #xA3              ; Append log record (3 topics)
   "LOG4" #xA4              ; Append log record (4 topics)
   
   ;; System Operations
   "CREATE" #xF0            ; Create a new account with associated code
   "CALL" #xF1              ; Message-call into an account
   "CALLCODE" #xF2          ; Message-call with another account's code
   "RETURN" #xF3            ; Halt execution and return output data
   "DELEGATECALL" #xF4      ; Message-call into this account with an alternative account's code
   "CREATE2" #xF5           ; Create a new account with associated code at a predictable address
   "STATICCALL" #xFA        ; Static message-call into an account
   "REVERT" #xFD            ; Halt execution, revert state changes, return output data
   "INVALID" #xFE           ; Invalid instruction
   "SELFDESTRUCT" #xFF      ; Halt and register account for deletion
   ))

;; opcodes: list
;; A list of all valid EVM opcode mnemonics (strings)
(define opcodes (hash-keys opcode-map))

;; byte->opcode: -> string
;; Reads a byte from standard input and returns the corresponding opcode mnemonic
;; This is used for disassembly (bytecode to opcode conversion)
;;
;; Returns:
;; - The opcode mnemonic corresponding to the byte read
(define (byte->opcode)
  (let ([byte (read-byte)])
    (hash-ref opcode-map byte)))

;; assemble-opcode: string -> string
;; Converts a single opcode or hex literal to its hexadecimal byte representation
;;
;; Parameters:
;; - opcode: An opcode mnemonic (e.g., "ADD") or hex literal (e.g., "0x60")
;;
;; Returns:
;; - The hexadecimal string representation of the opcode's byte value
;;
;; Raises:
;; - An error if the opcode is unknown
(define (assemble-opcode opcode)
  (cond
    ;; If it's a known opcode mnemonic, look up its byte value and convert to hex
    [(hash-has-key? opcode-map opcode) 
     (byte->hex (hash-ref opcode-map opcode))]
    
    ;; If it's a hex literal (starting with "0x"), strip the prefix
    [(string-prefix? opcode "0x") 
     (substring opcode 2)]
    
    ;; Otherwise, it's an unknown opcode
    [else (error "Unknown opcode" opcode)]))

;; assemble-opcodes: list -> list
;; Converts a list of opcodes to their hexadecimal byte representations
;;
;; Parameters:
;; - opcodes: A list of opcode mnemonics and/or hex literals
;;
;; Returns:
;; - A list of hexadecimal strings representing the byte values of the opcodes
(define (assemble-opcodes opcodes)
  (map assemble-opcode opcodes))

;; Export the opcode map, list of opcodes, and assembly functions
(provide opcode-map              ; Hash map of opcode mnemonics to byte values
         opcodes                 ; List of valid opcode mnemonics
         assemble-opcode         ; Function to assemble a single opcode
         assemble-opcodes)       ; Function to assemble multiple opcodes
