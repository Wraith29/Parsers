import strformat

const whitespace = " \t"
const blockers = @['\n', '\t', ' ', '=', '[', ']', '"']

type
  TokenKind* = enum
    LeftSqBracket, RightSqBracket
    Eof, Eq, Quote, Newline
    Ident

  Token* = ref object
    case kind*: TokenKind:
    of Ident: value*: string
    else: discard


func `$`*(token: Token): string =
  return case token.kind:
    of Ident: &"Token(kind: {token.kind}, value: {token.value})"
    else: &"Token(kind: {token.kind})"

iterator tokenise*(source: string): Token =
  var idx = 0
  var chr: char
  var ident: string
  var buildingIdent = false

  while idx < len(source):
    chr = source[idx]

    if chr in whitespace:
      inc idx
      continue

    if buildingIdent:
      if chr notin blockers:
        ident &= chr
        inc idx
        continue
      yield Token(kind: Ident, value: ident)

      buildingIdent = false
      ident = ""
    
    case chr:
    of '[': yield Token(kind: LeftSqBracket)
    of ']': yield Token(kind: RightSqBracket)
    of '=': yield Token(kind: Eq)
    of '"': yield Token(kind: Quote)
    of '\n': yield Token(kind: Newline)
    else:
      buildingIdent = true
      ident &= chr

    inc idx
  
  yield Token(kind: Eof)
