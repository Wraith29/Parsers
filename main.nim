import json
import toml
import result

proc main(): int =
  var contents = readFile("config.toml")
  var parser = newTomlParser(contents)
  let config = parser.parse().unwrap()

  echo $(%config)

  return 0


when isMainModule:
  quit(main())
