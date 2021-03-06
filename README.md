# Covfefe

[![Build Status](https://travis-ci.org/palle-k/Covfefe.svg?branch=master)](https://travis-ci.org/palle-k/Covfefe)
[![docs](https://cdn.rawgit.com/palle-k/Covfefe/66add420af3ce1801629d72ef0eedb9a30af584b/docs/badge.svg)](https://palle-k.github.io/Covfefe/)
[![CocoaPods](https://img.shields.io/cocoapods/v/Covfefe.svg)](https://cocoapods.org/pods/Covfefe)
![CocoaPods](https://img.shields.io/cocoapods/p/Covfefe.svg)
[![license](https://img.shields.io/github/license/palle-k/Covfefe.svg)](https://github.com/palle-k/Covfefe/blob/master/License)

Covfefe is a parser framework for languages generated by any (deterministic or nondeterministic) context free grammar.
It implements the [Earley](https://en.wikipedia.org/wiki/Earley_parser) and [CYK](https://en.wikipedia.org/wiki/CYK_algorithm) algorithm.

## Usage

### Swift Package Dependency in Xcode

1. Go to "File" > "Swift Packages" > "Add Package Dependency..."
2. Enter "https://github.com/palle-k/Covfefe.git" as the repository URL.
3. Select "Version", "Up to next major", "0.6.1" < "1.0.0"
4. Add Covfefe to your desired target.

### Swift Package Manager

This framework can be imported as a Swift Package by adding it as a dependency to the `Package.swift` file:

```swift
.package(url: "https://github.com/palle-k/Covfefe.git", from: "0.6.1")
```

### CocoaPods

Alternatively, it can be added as a dependency via CocoaPods (iOS, tvOS, watchOS and macOS).

```ruby
target 'Your-App-Name' do
  use_frameworks!
  pod 'Covfefe', '~> 0.6.1'
end
```

## Example

Grammars can be specified in a superset of EBNF or a superset of BNF, which adopts some features of EBNF (documented [here](/BNF.md)).
Alternatively, ABNF is supported.

```swift
let grammarString = """
expression       = binary-operation | brackets | unary-operation | number | variable;
brackets         = '(', expression, ')';
binary-operation = expression, binary-operator, expression;
binary-operator  = '+' | '-' | '*' | '/';
unary-operation  = unary-operator, expression;
unary-operator   = '+' | '-';
number           = {digit};
digit            = '0' ... '9';
variable         = {letter};
letter           = 'A' ... 'Z' | 'a' ... 'z';
""" 
let grammar = try Grammar(ebnf: grammarString, start: "expression")
```

This grammar describes simple mathematical expressions consisting of unary and binary operations and parentheses.
A syntax tree can be generated, which describes how a given word was derived from the grammar above:

 ```swift
let parser = EarleyParser(grammar: grammar)
 
let syntaxTree = try parser.syntaxTree(for: "(a+b)*(-c)")
 ```

![Example Syntax Tree](https://raw.githubusercontent.com/palle-k/Covfefe/master/example-syntax-tree.png)

For a more complete example, i.e. how to evaluate syntax tree, check out [ExpressionSolver](https://github.com/palle-k/ExpressionSolver).
