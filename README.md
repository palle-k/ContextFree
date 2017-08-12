# ContextFree

[![Build Status](https://travis-ci.org/palle-k/ContextFree.svg?branch=master)](https://travis-ci.org/palle-k/ContextFree)

ContextFree is a parser for languages generated by nondeterministic and deterministic context free grammars written in Swift.

Compared to regular languages (which can be expressed with regular expressions), context free languages are more powerful
as it is possible to perform counting operations (such as finding matching brackets in mathematical expressions).

For a given set of productions the parser is able to
produce a syntax tree for a word contained in the language
or to pinpoint syntax errors, if the word is not contained in the language.

## Example

The following code creates a grammar which can be used to parse arithmetic expressions.
`n(...)` creates a non terminal character, `t(...)` creates a terminal character.

```swift
let expression = try! "Expr" -->
        n("BinOperation")
	<|> n("Brackets")
	<|> n("UnOperation")
	<|> n("Num")
	<|> n("Var")
	<|> n("Whitespace") <+> n("Expr")
	<|> n("Expr") <+> n("Whitespace")

let BracketExpr 	= "Brackets" 			--> t("(") <+> n("Expr") <+> t(")")
let BinOperation 	= "BinOperation" 		--> n("Expr") <+> n("Op") <+> n("Expr")
let BinOp 			= "Op" 					--> t("+") <|> t("-") <|> t("*") <|> t("/")
let UnOperation 	= "UnOperation" 		--> n("UnOp") <+> n("Expr")
let UnOp 			= "UnOp" 				--> t("+") <|> t("-")
let Num 			= try! "Num" 			--> rt("\\b\\d+(\\.\\d+)?\\b")
let Var 			= try! "Var" 			--> rt("\\b[a-zA-Z_][a-zA-Z0-9_]*\\b")
let Whitespace 	= try! "Whitespace" 	--> rt("\\s+")

let grammar = Grammar(productions: expression + BinOp + UnOp + [Num, Var, BracketExpr, BinOperation, UnOperation, Whitespace], start: "Expr")
```

This grammar can then be used to check if an arithmetic expression is valid.

In a valid expression, all parentheses are closed again and 
binary operators always have a left side and a right side operand.

A syntax tree can be generated, which describes the structure of a given word:

 ```swift
 let syntaxTree = try grammar.generateSyntaxTree(for: "(a+b)*(-c)")
 ```

<img src="example-syntax-tree.png"/>
