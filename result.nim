const AnsiRed = "\u001b[31m"
const AnsiReset = "\u001b[0m"

type
  ResultKind = enum
    Ok, Err
  
  Result*[T] = ref object
    case kind: ResultKind:
    of Ok: value: T
    of Err: msg: string

proc ok*[T](value: T): Result[T] =
  return Result[T](kind: Ok, value: value)

proc err*[T](msg: string): Result[T] =
  return Result[T](kind: Err, msg: msg)

proc isOk*(res: Result): bool =
  return case res.kind:
    of Ok: true
    of Err: false

proc isErr*(res: Result): bool =
  return case res.kind:
    of Err: true
    of Ok: false

proc value*[T](res: Result[T]): T =
  assert res.isOk(), "Result is not Ok"
  return res.value

proc msg*[T](res: Result[T]): string =
  assert res.isErr(), "Result is not Err"
  return res.msg

proc unwrap*[T](res: Result[T]): T =
  if isErr res:
    echo AnsiRed, "Error: ", res.msg, AnsiReset
    quit(1)
  
  return res.value
