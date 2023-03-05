import json
import options
import strutils
import strformat
import sugar
import result

#-- Region Tokeniser --#

const Whitespace = " \t\r"
const Blockers = @['\r', '\n', '\t', '=', '[', ']', '"']

type
  TokenKind = enum
    LeftSqBracket
    RightSqBracket
    Eq
    Quote
    Newline
    Eof
    Ident

  Token = ref object
    case kind: TokenKind:
    of Ident: value*: string
    else: discard

func newToken(kind: TokenKind): Token =
  Token(kind: kind)

func newIdent(value: string): Token =
  Token(kind: Ident, value: value)

iterator tokenise(src: string): Token =
  var idx = 0
  var chr: char
  var ident: string
  var building = false

  while idx < len(src):
    chr = src[idx]

    if building:
      if chr notin Blockers:
        ident &= chr
        idx += 1
        continue
        
      yield newIdent(ident)
    
      building = false
      ident = ""
    
    if chr in Whitespace:
      idx += 1
      continue
    
    case chr:
    of '[': yield newToken(LeftSqBracket)
    of ']': yield newToken(RightSqBracket)
    of '=': yield newToken(Eq)
    of '"': yield newToken(Quote)
    of '\n': yield newToken(Newline)
    else:
      building = true
      ident &= chr
    idx += 1
  
  yield newToken(Eof)

#-- Endregion Tokeniser --#

#-- Region Parser --#

type
  TomlValueKind = enum  
    String
    Bool
    Int

  TomlValue = ref object
    case kind: TomlValueKind:
    of String: strVal: string
    of Bool: boolVal: bool
    of Int: intVal: int
  
  TomlPair = ref object
    key: string
    value: TomlValue
  
  TomlSection = ref object
    name: string
    pairs: seq[TomlPair]

  Toml = ref object
    sections: seq[TomlSection]
  
  TomlParser = ref object
    tokens: seq[Token]
    idx: int

func newTomlParser*(src: string): TomlParser =
  let tokens = collect:
    for token in tokenise(src): token
  
  return TomlParser(tokens: tokens, idx: 0)

template current(parser: TomlParser): Token =
  parser.tokens[parser.idx]

template skipWhitespace(parser: TomlParser) =
  while parser.tokens[parser.idx].kind == Newline:
    parser.idx += 1

proc expect(parser: TomlParser, tokenKind: TokenKind): Result[bool] =
  let token = parser.current()
  if token.kind != tokenKind:
    return err[bool](fmt"Expected {tokenKind}, but found {token.kind}")

  parser.idx += 1
  return ok(true)

proc consume(parser: TomlParser, tokenKind: TokenKind): Result[Token] =
  let token = parser.current()
  if token.kind != tokenKind:
    return err[Token](fmt"Expected {tokenKind}, but found {token.kind}")

  parser.idx += 1
  return ok(token)

proc parseString(parser: TomlParser): Result[TomlValue] =
  parser.skipWhitespace()
  
  discard parser.expect(Quote).unwrap()
  let value = parser.consume(Ident).unwrap()
  discard parser.expect(Quote).unwrap()

  return ok(TomlValue(kind: String, strVal: value.value))

proc parseIntOrbool(parser: TomlParser): Result[TomlValue] =
  parser.skipWhitespace()

  let value = parser.consume(Ident).unwrap()

  if value.value == "true":
    return ok(TomlValue(kind: Bool, boolVal: true))
  elif value.value == "false":
    return ok(TomlValue(kind: Bool, boolVal: false))

  return ok(TomlValue(kind: Int, intVal: parseInt(value.value)))

proc parsePair(parser: TomlParser): Result[Option[TomlPair]] =
  parser.skipWhitespace()

  if parser.current().kind != Ident:
    return ok(none[TomlPair]())

  let key = parser.consume(Ident).unwrap()

  discard parser.expect(Eq).unwrap()

  var value: TomlValue
  if parser.current().kind == Quote:
    value = parser.parseString().unwrap()
  else:
    value = parser.parseIntOrBool().unwrap()
  
  return ok(some(TomlPair(key: key.value, value: value)))

proc parseSection(parser: TomlParser): Result[Option[TomlSection]] =
  parser.skipWhitespace()
  
  if parser.current().kind != LeftSqBracket:
    return ok(none[TomlSection]())

  discard parser.expect(LeftSqBracket).unwrap()
  let name = parser.consume(Ident).unwrap()
  discard parser.expect(RightSqBracket)

  var pairs = newSeq[TomlPair]()

  while true:
    let pair = parser.parsePair()
    if isErr pair:
      return err[Option[TomlSection]](pair.msg())

    if isNone pair.value():
      break
      
    pairs.add(pair.value().get())
  
  return ok(some(TomlSection(name: name.value, pairs: pairs)))

proc parse*(parser: TomlParser): Result[Toml] =
  var toml = new Toml

  while parser.tokens[parser.idx].kind != Eof:
    let section = parser.parseSection()
    if isErr section:
      return err[Toml](section.msg())

    if isNone section.value():
      parser.idx += 1
      continue

    toml.sections.add(section.value().get())
  
  return ok(toml)

#-- Endregion Parser --#
