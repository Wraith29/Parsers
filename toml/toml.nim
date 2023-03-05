import result
import parser

proc main(): int =
  var src = "[editor]\nusername=\"Isaac\""

  var parser = newTomlParser(src)
  let config = parser.parse().unwrap()

  echo config
  
  return 0


when isMainModule:
  quit(main())