import json
import result
import parser

proc main(): int =
  var src = """[editor]
  username="Isaac"
  age=20
  isCool=true

  [editor.defaults]
  cheese="Hello"
  """

  var parser = newTomlParser(src)
  let config = parser.parse().unwrap()

  echo $(%config)
  
  return 0


when isMainModule:
  quit(main())
