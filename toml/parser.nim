import strformat
import sugar

import token
import result

#[
  Toml(
    Section(
      Name(string),
      Pair(key, value),
      Pair(key, value),
    ),
    Section(
      Name(string),
      Pair(key, value),
      Subsection(
        Name(),
        Pair(key, value)
      )
    )
  )
]#

type
  TomlValueKind = enum
    String, Int, Bool
  
  TomlValue = ref object
    case kind: TomlValueKind:
    of String: strVal: string
    of Int: intVal: int
    of Bool: boolVal: bool

proc parseTomlValue(value: string): TomlValue =
  echo value

  TomlValue(kind: String, strVal: "hi")

type
  TomlPair = ref object
    key: string
    value: TomlValue

  TomlSection = ref object
    name: string
    pairs: seq[TomlPair]
    subsections: seq[TomlSection]

  Toml = ref object
    sections: seq[TomlSection]

  TomlParser* = ref object
    toml: Toml
    tokens: seq[Token]
    idx: int

func newTomlParser*(src: string): TomlParser =
  let tokens = collect:
    for tkn in tokenise(src): tkn
    
  TomlParser(tokens: tokens, idx: 0)

proc expect(parser: TomlParser, tk: TokenKind): Result[bool] =
  ## Check that the current token is of kind `tk`
  ## Advance the parser to the next token
  ## If the token is not the right kind, returns an err
  let token = parser.tokens[parser.idx]
  if token.kind == tk:
    parser.idx += 1
    return ok(true)
  
  return err[bool](&"Expected {tk}, but found {token.kind}")

proc expectAndCollect(parser: TomlParser, tk: TokenKind): Result[Token] =
  ## Check that the current token is of kind `tk`
  ## Advance the parser to the next token
  ## If the token is not the right kind, returns an err
  let token = parser.tokens[parser.idx]
  if token.kind == tk:
    parser.idx += 1
    return ok(token)

  return err[Token](&"Expect {tk}, but found {token.kind}")

proc parseSection(parser: TomlParser): Result[TomlSection] =
  var section = new TomlSection

  discard parser.expect(LeftSqBracket).unwrap()
  let ident = parser.expectAndCollect(Ident).unwrap()
  discard parser.expect(RightSqBracket).unwrap()

  section.name = ident.value

  var parsingPairs = true

  while parsingPairs:
    var pair = new TomlPair
    discard parser.expect(Newline).unwrap()
    let key = parser.expectAndCollect(Ident).unwrap()
    discard parser.expect(Eq).unwrap()
    let value = parser.expectAndCollect(Ident).unwrap()
    pair.key = key.value
    pair.value = parseTomlValue(value.value)

proc parse*(parser: TomlParser): Result[Toml] =
  var toml = new Toml

  while parser.idx < len(parser.tokens):
    let section = parser.parseSection().unwrap()

func `$`*(value: TomlValue): string =
  case value.kind:
  of String: &"Value(kind: String, value: {value.strVal})"
  of Int: &"Value(kind: Int, value: {value.intVal})"
  of Bool: &"Value(kind: Bool, value: {value.boolVal})"

func `$`*(pair: TomlPair): string =
  &"Pair(key: {pair.key}, value: {pair.value})"

func `$`*(sec: TomlSection): string =
  &"Section(name: {sec.name}, pairs: {sec.pairs}, subsections: {sec.subsections})"

func `$`*(toml: Toml): string =
  &"Toml(sections: {toml.sections})"