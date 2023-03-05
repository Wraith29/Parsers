const
  AnsiRed = "\u001b[31m"
  AnsiReset = "\u001b[0m"

type
  ResultKind = enum
    Ok, Err
  
  Result*[T] = ref object
    case kind: ResultKind:
    of Ok: value: T
    of Err: msg: string

proc ok*[T](value: T): Result[T] =
  Result[T](kind: Ok, value: value)

proc err*[T](msg: string): Result[T] =
  Result[T](kind: Err, msg: msg)

proc isOk*(res: Result): bool =
  case res.kind:
  of Ok: true
  of Err: false

proc isErr*(res: Result): bool =
  case res.kind:
  of Err: true
  of Ok: false

proc value*[T](res: Result[T]): T =
  assert(res.isOk(), "Result is not Ok Kind")
  res.value

proc msg*[T](res: Result[T]): string =
  assert(res.isErr(), "Result is not Error Kind")
  res.msg

proc unwrap*[T](res: Result[T]): T =
  ## "Unwraps" the result, quitting the program if the result is of error type.
  ## Otherwise returns the value wanted
  ## Probably want this to generate a warning as it shouldn't be used but is convenient
  if isErr res:
    echo AnsiRed, "ERROR: ", res.msg, AnsiReset
    quit(1)
  
  return res.value