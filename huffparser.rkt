#lang brag
program : @top-level*
top-level : (function-abi-definition | event-abi-definition | deferror | defconst | macro-definition | fn-definition | include | COMMENT)*
include: /INCLUDE STRING
function-abi-definition : FUNCDEFINE
event-abi-definition: EVENTDEFINE
deferror : /DEFINE /ERROR IDENTIFIER args
defconst : /DEFINE /CONSTANT IDENTIFIER /EQUALS (HEX | FREE_STORAGE_POINTER)
deftable : /DEFINE /TABLE IDENTIFIER scope
macro-definition : /DEFINE /MACRO IDENTIFIER args /EQUALS takes returns scope
fn-definition : /DEFINE /FN IDENTIFIER args /EQUALS takes returns scope
args : /LPAREN @identifierlist* /RPAREN
takes : /TAKES /LPAREN NUMBER /RPAREN
returns : /RETURNS /LPAREN NUMBER /RPAREN
scope : /LBRACE body /RBRACE
body : (OPCODE | HEX | invocation | label | macro-arg | label-ref | IDENTIFIER | /COMMENT)*
macro-arg : /LT IDENTIFIER /GT
label: IDENTIFIER /COLON
label-ref : /LBRACKET IDENTIFIER /RBRACKET
invocation : IDENTIFIER /LPAREN @identifierlist* /RPAREN scope?
identifierlist : @ident (COMMA @ident)*
ident : (IDENTIFIER | macro-arg | OPCODE | HEX | NUMBER)
