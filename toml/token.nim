import strutils
import strformat

const whitespace = " \t"
const blockers = @['\n', '\t', ' ', '=', '[', ']', '"']

type
  TokenKind* = enum
    LeftSqBracket, RightSqBracket
    Eof, Eq, Quote, Newline
    Ident

  Token* = ref object
    line*, col*: int
    case kind*: TokenKind:
    of Ident: value*: string
    else: discard

func newToken(kind: TokenKind, line, col: int): Token =
  Token(line: line, col: col, kind: kind)

func newIdent(value: string, line, col: int): Token =
  Token(line: line, col: col, kind: Ident, value: value)


func `$`*(token: Token): string =
  return case token.kind:
    of Ident: &"Token(kind: {token.kind}, value: {token.value}, line: {token.line}, col: {token.col})"
    else: &"Token(kind: {token.kind}, line: {token.line}, col: {token.col})"

func getLengthOfCurrentLine(src: string, line: int): int =
  let lines = src.split('\n')

  return len(lines[line])

func getLineNumber(src: string, index: int): int =
  return src[0..index].count('\n')

func getColumn(src: string, index: int): int =
  let lineNumber = getLineNumber(src, index)
  var lengthOfPreviousLines = 0

  for i in 0..<lineNumber:
    lengthOfPreviousLines += getLengthOfCurrentLine(src, i)
  
  return index-lengthOfPreviousLines

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

    let line = getLineNumber(source, idx)
    let col = getColumn(source, idx)

    if buildingIdent:
      if chr notin blockers:
        ident &= chr
        inc idx
        continue
      yield newIdent(ident, line, col)

      buildingIdent = false
      ident = ""
    
    case chr:
    of '[': yield newToken(LeftSqBracket, line, col)
    of ']': yield newToken(RightSqBracket, line, col)
    of '=': yield newToken(Eq, line, col)
    of '"': yield newToken(Quote, line, col)
    of '\n': yield newToken(Newline, line, col)
    else:
      buildingIdent = true
      ident &= chr

    inc idx
  
  yield Token(kind: Eof)
