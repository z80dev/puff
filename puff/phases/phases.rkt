#lang racket/base
;;; phases.rkt - Compilation phases aggregator for Puff
;;;
;;; This file serves as a central aggregation point for all the compiler phases.
;;; Each phase represents a specific transformation in the compilation pipeline
;;; that converts Huff code into EVM bytecode. The phases are applied sequentially,
;;; with each phase building on the transformations performed by the previous ones.

;; Constants resolution phase - replaces constant references with their values
(require "constants.rkt")

;; Function signature generation phase - resolves function signature hashes
(require "funcsigs.rkt")

;; Error signature generation phase - resolves error signature hashes
(require "errors.rkt")

;; Event signature generation phase - resolves event signature hashes
(require "events.rkt")

;; Hex value conversion phase - converts hex literals to appropriate PUSH instructions
(require "hexvals.rkt")

;; Opcode translation phase - converts opcode names to their byte values
(require "opcodes.rkt")

;; Label resolution phase - resolves jump labels to concrete offsets
(require "labels.rkt")

;; Macro expansion phase - replaces macro calls with their expanded bodies
(require "macros.rkt")

;; Free storage pointer phase - handles FREE_STORAGE_POINTER() calls
(require "fsp.rkt")

;; Export all phase transformations
;; These functions are used in the pipeline defined in puff.rkt
(provide 
 ;; Convert opcode mnemonics (like ADD, MUL) to their EVM byte values
 insert-opcodes
 
 ;; Resolve jump labels to their numerical offsets
 insert-labels
 
 ;; Replace event signature references with Keccak-256 hashes
 insert-eventsigs
 
 ;; Replace error signature references with Keccak-256 hashes
 insert-errorsigs
 
 ;; Replace function signature references with Keccak-256 hashes (first 4 bytes)
 insert-funcsigs
 
 ;; Convert hex literals to appropriate PUSH instructions
 insert-hexvals
 
 ;; Handle FREE_STORAGE_POINTER() calls for storage allocation
 insert-fsp
 
 ;; Replace constant references with their actual values
 insert-constants
 
 ;; Expand macro calls by replacing them with their bodies
 insert-macros)
