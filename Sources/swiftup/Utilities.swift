/*
  swiftup
  The Swift toolchain installer

  Copyright (C) 2016-present swiftup Authors

  Authors:
    Muhammad Mominul Huque
*/

import Glibc
import Spawn
import Environment

func unimplemented() {
  print("Not Implemented!")
  exit(1)
}

func getTempDir() -> String {
  return Env["TMPDIR"] ?? "/tmp"
}

func run(program: String, arguments: [String]) {
  /*
  let pipe = Pipe()
  let task = Process()

  task.launchPath = program
  task.arguments = arguments
  task.standardOutput = pipe

  task.launch()
  task.waitUntilExit()

  let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!

  if output.characters.count > 2 {
    print(output)
  }*/

  do {
    _ = try Spawn(args: [program] + arguments)
  } catch {
    print("error: \(error)", color: .red)
  }
}

func moveItem(src: String, dest: String) {
  run(program: "/bin/mv", arguments: ["\(src)", "\(dest)"])
}

extension String {
  func addingPath(_ path: String) -> String {
    if (hasSuffix("/") && !path.hasPrefix("/")) || (!hasSuffix("/") && path.hasPrefix("/")) {
      return self + path
    } else if hasSuffix("/") && path.hasPrefix("/") {
      return String(characters.dropLast(1)) + path
    } else {
      return self + "/" + path
    }
  }

  var isUrl: Bool {
    return hasPrefix("https://")
  }
}
