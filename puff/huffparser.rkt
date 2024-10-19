#lang brag
program : @top-level*
top-level : (declfn | event-abi-definition | deferror | defconst | defmacro | defn | include | COMMENT)*
include: /INCLUDE STRING
declfn : FUNCDECLARE
event-abi-definition: EVENTDEFINE
deferror : /DEFINE /ERROR IDENTIFIER args
defconst : /DEFINE /CONSTANT IDENTIFIER /EQUALS (hex | FREE-STORAGE-POINTER)
deftable : /DEFINE /TABLE IDENTIFIER scope
defmacro : /DEFINE /MACRO IDENTIFIER args /EQUALS takes returns @scope
defn : /DEFINE /FN IDENTIFIER args /EQUALS takes returns @scope
args : /LPAREN @identifierlist* /RPAREN
takes : /TAKES /LPAREN NUMBER /RPAREN
returns : /RETURNS /LPAREN NUMBER /RPAREN
scope : /LBRACE body /RBRACE
body : (hex | fncall | label | macro-arg | const-ref | IDENTIFIER | /COMMENT)*
macro-arg : /LT IDENTIFIER /GT
label: IDENTIFIER /COLON
const-ref : /LBRACKET IDENTIFIER /RBRACKET
fncall : IDENTIFIER args
fncall-with-scope : IDENTIFIER /LPAREN @identifierlist* /RPAREN @scope?
identifierlist : @ident (COMMA @ident)*
ident : (IDENTIFIER | macro-arg | hex | NUMBER)
hex : HEX
opcode: OPCODE