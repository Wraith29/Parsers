# TODO: Remove all Unwraps
import strutils
import strformat
import sugar
import token
import options
import result

type
  TomlValueKind = enum
    String, Int, Bool

  TomlValue = ref object
    case kind: TomlValueKind:
    of String: strVal: string
    of Int: intVal: int
    of Bool: boolVal: bool
  
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

proc newTomlParser*(src: string): TomlParser =
  let tokens = collect:
    for token in tokenise(src):
      token
  
  return TomlParser(tokens: tokens, idx: 0)

proc current(parser: TomlParser): Token =
  return parser.tokens[parser.idx]

proc expect(parser: TomlParser, tokenKind: TokenKind): Result[bool] =
  ## A result is not exactly the ideal type here
  ## There isn't really anything that needs returning from this function
  ## We purely need to know if it has failed or not.
  let token = parser.current()
  if token.kind != tokenKind:
    return err[bool](fmt"Expected {tokenKind}, but found {token.kind}")

  # Increment the token
  parser.idx += 1
  return ok(true)

proc expectAndCollect(parser: TomlParser, tokenKind: TokenKind): Result[Token] =
  ## This does the same as expect, except it will collect the token and return it too
  let token = parser.current()
  if token.kind != tokenKind:
    return err[Token](fmt"ERROR: toml/parser.nim {token.line}:{token.col} Expected {tokenKind}, but found {token.kind}")
  
  parser.idx += 1
  return ok(token)

proc skipWhitespace(parser: TomlParser) =
  while parser.tokens[parser.idx].kind == Newline:
    parser.idx += 1

proc parseString(parser: TomlParser): Result[TomlValue] =
  parser.skipWhitespace()
  discard parser.expect(Quote)
  let ident = parser.expectAndCollect(Ident).unwrap()
  discard parser.expect(Quote)

  return ok(TomlValue(kind: String, strVal: ident.value))

proc parseIntOrBool(parser: TomlParser): Result[TomlValue] =
  parser.skipWhitespace()

  let ident = parser.expectAndCollect(Ident).unwrap()
  
  if ident.value == "true":
    return ok(TomlValue(kind: Bool, boolVal: true))
  elif ident.value == "false":
    return ok(TomlValue(kind: Bool, boolVal: false))

  return ok(TomlValue(kind: Int, intVal: parseInt(ident.value)))

proc parsePair(parser: TomlParser): Result[Option[TomlPair]] =
  parser.skipWhitespace()
  if parser.current().kind != Ident:
    return ok(none(TomlPair))
  
  let key = parser.expectAndCollect(Ident).unwrap()
  
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
    # If we aren't starting on a LeftSqBracket
    # We are not parsing a section.
    # Not an error, just to exit with none
    return ok(none(TomlSection))

  discard parser.expect(LeftSqBracket).unwrap()
  let name = parser.expectAndCollect(Ident).unwrap()
  discard parser.expect(RightSqBracket).unwrap()
  
  var pairs = newSeq[TomlPair]()

  while true:
    let pair = parser.parsePair()
    if isErr pair:
      return err[Option[TomlSection]](pair.msg()) 
    
    if isNone pair.value():
      break
    
    pairs.add(pair.value().get)

  return ok(some(TomlSection(name: name.value, pairs: pairs)))

proc parse*(parser: TomlParser): Result[Toml] =
  var toml = new Toml
  
  # While we are not at the end of the file
  while parser.tokens[parser.idx].kind != Eof:
    let section = parser.parseSection()
    if isErr section:
      return err[Toml](section.msg())
    
    if isNone section.value():
      parser.idx += 1
      continue
  
    toml.sections.add(section.value().get())
  
  return ok(toml)
