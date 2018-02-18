//
//  EBNFImporter.swift
//  Covfefe
//
//  Created by Palle Klewitz on 14.08.17.
//  Copyright (c) 2017 Palle Klewitz
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// A grammar describing the Backus-Naur form
var bnfGrammar: Grammar {
	
	let syntax = "syntax" --> n("rule") <|> n("rule") <+> n("newlines") <|> n("syntax") <+> n("newlines") <+> n("rule") <+> (n("newlines") <|> [[]])
	let rule = "rule" --> n("optional-whitespace") <+> n("rule-name-container") <+> n("optional-whitespace") <+> n("assignment-operator") <+> n("optional-whitespace") <+> n("expression") <+> n("optional-whitespace")
	
	let optionalWhitespace = "optional-whitespace" --> [[]] <|> SymbolSet.whitespace <|> SymbolSet.whitespace <+> [n("optional-whitespace")]
	let newlines = "newlines" --> t("\n") <|> t("\n") <+> n("optional-whitespace") <+> n("newlines")
	
	let assignmentOperator = "assignment-operator" --> t(":") <+> t(":") <+> t("=")
	
	let ruleNameContainer = "rule-name-container" --> t("<") <+> n("rule-name") <+> t(">")
	let ruleName = "rule-name" --> n("rule-name") <+> n("rule-name-char") <|> [[]]
	let ruleNameChar = try! "rule-name-char" --> rt("[a-zA-Z0-9-_]")
	
	let expression = "expression" --> n("concatenation") <|> n("alternation")
	let alternation = "alternation" --> n("expression") <+> n("optional-whitespace") <+> t("|") <+> n("optional-whitespace") <+> n("concatenation")
	let concatenation = "concatenation" --> n("expression-element") <|> n("concatenation") <+> n("optional-whitespace") <+> n("expression-element")
	let expressionElement = "expression-element" --> n("literal") <|> n("rule-name-container")
	let literal = "literal" --> t("'") <+> n("string-1") <+> t("'") <|> t("\"") <+> n("string-2") <+> t("\"")
	let string1 = "string-1" --> n("string-1") <+> n("string-1-char") <|> [[]]
	let string2 = "string-2" --> n("string-2") <+> n("string-2-char") <|> [[]]
	
	// no ', \, \r or \n
	let string1char = try! "string-1-char" --> rt("[^'\\\\\r\n]") <|> n("string-escaped-char")
	let string2char = try! "string-2-char" --> rt("[^\"\\\\\r\n]") <|> n("string-escaped-char")
	
	let stringEscapedChar = "string-escaped-char" --> n("unicode-scalar") <|> n("carriage-return") <|> n("line-feed") <|> n("tab-char") <|> n("backslash")
	let unicodeScalar = "unicode-scalar" --> t("\\") <+> t("u") <+> t("{") <+>  n("unicode-scalar-digits") <+> t("}")
	let unicodeScalarDigits = "unicode-scalar-digits" --> [n("digit")] <+> (n("digit") <|> [[]]) <+> (n("digit") <|> [[]]) <+> (n("digit") <|> [[]]) <+> (n("digit") <|> [[]]) <+> (n("digit") <|> [[]]) <+> (n("digit") <|> [[]]) <+> (n("digit") <|> [[]])
	let digit = try! "digit" --> rt("[0-9a-fA-F]")
	let carriageReturn = "carriage-return" --> t("\\") <+> t("r")
	let lineFeed = "line-feed" --> t("\\") <+> t("n")
	let tabChar = "tab-char" --> t("\\") <+> t("t")
	let backslash = "backslash" --> t("\\") <+> t("\\")
	
	var productions: [Production] = []
	productions.append(contentsOf: syntax)
	productions.append(rule)
	productions.append(contentsOf: optionalWhitespace)
	productions.append(contentsOf: newlines)
	productions.append(assignmentOperator)
	productions.append(ruleNameContainer)
	productions.append(contentsOf: ruleName)
	productions.append(ruleNameChar)
	productions.append(contentsOf: expression)
	productions.append(alternation)
	productions.append(contentsOf: concatenation)
	productions.append(contentsOf: expressionElement)
	productions.append(contentsOf: literal)
	productions.append(contentsOf: string1)
	productions.append(contentsOf: string2)
	productions.append(contentsOf: string1char)
	productions.append(contentsOf: string2char)
	productions.append(contentsOf: stringEscapedChar)
	productions.append(unicodeScalar)
	productions.append(contentsOf: unicodeScalarDigits)
	productions.append(digit)
	productions.append(carriageReturn)
	productions.append(lineFeed)
	productions.append(tabChar)
	productions.append(backslash)
	
	return Grammar(productions: productions, start: "syntax")
}

enum StringLiteralParsingError: Error {
	case invalidUnicodeScalar(Int)
}

public extension Grammar {
	
	/// Creates a new grammar from a specification in Backus-Naur Form (BNF)
	///
	/// 	<pattern1> ::= <alternative1> | <alternative2>
	///		<pattern2> ::= 'con' 'catenation'
	///
	/// - Parameters:
	///   - bnfString: String describing the grammar in BNF
	///   - start: Start non-terminal
	public init(bnfString: String, start: String) throws {
		let grammar = bnfGrammar
		let tokenizer = DefaultTokenizer(grammar: grammar)
		let parser = EarleyParser(grammar: grammar)
		let syntaxTree = try parser
			.syntaxTree(for: bnfString)
			.explode{["expression"].contains($0)}
			.first!
			.filter{!["optional-whitespace", "newlines"].contains($0)}!
		
		let ruleDeclarations = syntaxTree.allNodes(where: {$0.name == "rule"})
		
		func ruleName(from container: SyntaxTree<NonTerminal, Range<String.Index>>) -> String {
			return container
				.allNodes(where: {$0.name == "rule-name-char"})
				.flatMap{$0.leafs}
				.reduce("") { partialResult, range -> String in
					partialResult.appending(bnfString[range])
			}
		}
		
		func string(fromCharacterExpression characterExpression: ParseTree) throws -> String {
			guard let child = characterExpression.children?.first else {
				fatalError()
			}
			switch child {
			case .leaf(let range):
				return String(bnfString[range])
				
			case .node(key: "string-escaped-char", children: let children):
				guard let child = children.first else {
					fatalError()
				}
				switch child {
				case .leaf:
					fatalError()
					
				case .node(key: "unicode-scalar", children: let children):
					let hexString: String = children.dropFirst(3).dropLast().flatMap {$0.leafs}.map {bnfString[$0]}.joined()
					// Grammar guarantees that hexString is always a valid hex integer literal
					let charValue = Int(hexString, radix: 16)!
					guard let scalar = UnicodeScalar(charValue) else {
						throw StringLiteralParsingError.invalidUnicodeScalar(charValue)
					}
					return String(scalar)
				
				case .node(key: "carriage-return", children: _):
					return "\r"
					
				case .node(key: "line-feed", children: _):
					return "\n"
					
				case .node(key: "tab-char", children: _):
					return "\t"
					
				case .node(key: "backslash", children: _):
					return "\\"
					
				default:
					fatalError()
				}
				
			default:
				fatalError()
			}
		}
		
		func string(fromStringExpression stringExpression: ParseTree, knownString: String = "") throws -> String {
			if let children = stringExpression.children, children.count == 2 {
				let character = try string(fromCharacterExpression: children[1])
				return try string(fromStringExpression: children[0], knownString: "\(character)\(knownString)")
			} else {
				return knownString
			}
		}
		
		func string(fromLiteral literal: ParseTree) throws -> String {
			guard let children = literal.children, children.count == 3 else {
				fatalError("Invalid parse tree")
			}
			let stringNode = children[1]
			return try string(fromStringExpression: stringNode)
		}
		
		func makeProductions(from expression: SyntaxTree<NonTerminal, Range<String.Index>>, named name: String) throws -> [Production] {
			guard let type = expression.root?.name else {
				return []
			}
			guard let children = expression.children else {
				return []
			}
			switch type {
			case "alternation":
				return try makeProductions(from: children[0], named: name) + makeProductions(from: children[2], named: name)
				
			case "concatenation":
				if children.count == 2 {
					let lhsProduction = try makeProductions(from: children[0], named: name)
					let rhsProduction = try makeProductions(from: children[1], named: name)
					assert(lhsProduction.count == 1)
					assert(rhsProduction.count == 1)
					return [Production(pattern: NonTerminal(name: name), production: lhsProduction[0].production + rhsProduction[0].production)]
				} else if children.count == 1 {
					return try makeProductions(from: children[0], named: name)
				} else {
					fatalError()
				}
				
			case "expression-element":
				guard children.count == 1 else {
					return []
				}
				switch children[0].root!.name {
				case "literal":
					let terminalValue = try string(fromLiteral: children[0])
					if terminalValue.isEmpty {
						return [Production(pattern: NonTerminal(name: name), production: [])]
					} else {
						return [Production(pattern: NonTerminal(name: name), production: [t(terminalValue)])]
					}
					
				case "rule-name-container":
					let nonTerminalName = ruleName(from: children[0])
					return [Production(pattern: NonTerminal(name: name), production: [n(nonTerminalName)])]
					
				default:
					fatalError()
				}
				
			default:
				fatalError()
			}
		}
		
		let productions = try ruleDeclarations.flatMap { ruleDeclaration -> [Production] in
			guard let children = ruleDeclaration.children, children.count == 3 else {
				return []
			}
			let name = ruleName(from: children[0])
			return try makeProductions(from: children[2], named: name)
		}
		
		if productions.contains(where: { (production: Production) -> Bool in
			production.generatedNonTerminals.contains("EOL")
		}) && !productions.contains(where: { (production: Production) -> Bool in
			production.pattern == "EOL"
		}) {
			self.init(productions: productions + ["EOL" --> t("\n")], start: NonTerminal(name: start))
		} else {
			self.init(productions: productions, start: NonTerminal(name: start))
		}
		
	}
}
