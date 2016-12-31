/*
  swiftup
  The Swift toolchain installer

  Copyright (C) 2016-present swiftup Authors

  Authors:
    Muhammad Mominul Huque
*/

import libNix
import Foundation
import Environment

struct Toolchains {
  var versioningFolder: String {
    if let path = Env["SWIFTUP_ROOT"] {
      return path.addingPath("versions")
    }

    return ""
  }

  var globalVersion: String {
    get {
      //return (try? String(contentsOfFile: Env["SWIFTUP_ROOT"]!.addingPath("version"), encoding: .utf8)) ?? ""
      return (try? getContentsOf(file: Env["SWIFTUP_ROOT"]!.addingPath("version"))) ?? ""
    }

    set {
      if isInstalled(version: newValue) {
        try? newValue.write(toFile: Env["SWIFTUP_ROOT"]!.addingPath("version"), atomically: true, encoding: .utf8)
      } else {
        print("Version \(newValue) is not installed!")
      }
    }
  }

  func installedVersions() -> [String]? {
    //let paths = try? FileManager.default.contentsOfDirectory(atPath: versioningFolder)
    let paths = try? contentsOfDirectory(atPath: versioningFolder)
    return paths
  }

  func isInstalled(version: String) -> Bool {
    if let versions = installedVersions() {
      return versions.contains {
        return ($0 == version) ? true : false
      }
    }

    return false
  }

  func getBinaryPath() -> String {
    return versioningFolder.addingPath(globalVersion).addingPath("usr/bin/")
  }

  mutating func installToolchain(version: String) {
    let distribution = Distribution(target: version)

    guard !isInstalled(version: distribution.versionName) else {
      print("Version \(distribution.versionName) is already installed!")
      return
    }

    print("Will install version \(distribution.versionName)")
    installTarToolchain(distribution: distribution)
    print("Version \(distribution.versionName) has been installed!")

    globalVersion = distribution.versionName
    rehashToolchain()
  }

  func installTarToolchain(distribution: Distribution) {
    let tempDir = getTempDir().addingPath("swiftup-\(distribution.versionName)")
    let tempFile = tempDir.addingPath("toolchain.tar.gz")
    let tempEFile = tempDir.addingPath("\(distribution.fileName)")
    let installDir = Toolchains().versioningFolder.addingPath("\(distribution.versionName)")

    // Create temp direcyory
    _ = try! FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

    print("Downloading toolchain \(distribution.downloadUrl)")

    run(program: "/usr/bin/curl", arguments: ["-C", "-", "\(distribution.downloadUrl)", "-o", "\(tempFile)"])

    guard FileManager.default.fileExists(atPath: tempFile) else {
      print("Error occurred when downloading the toolchain")
      exit(1)
    }

    run(program: "/bin/tar", arguments: ["xzf", "\(tempFile)", "-C", "\(tempDir)"])

    guard FileManager.default.fileExists(atPath: tempEFile) else {
      print("Error occurred when extracting the toolchain")
      exit(1)
    }

    moveItem(src: tempEFile, dest: installDir)

    guard FileManager.default.fileExists(atPath: installDir) else {
      print("Error occurred when installing the toolchain")
      exit(1)
    }
  }

  func rehashToolchain() {
    let binaryDir = versioningFolder.addingPath(globalVersion).addingPath("usr/bin")

    let binaries = try! contentsOfDirectory(atPath: binaryDir)

    func createShims(name: String) {
      let script = "#!/usr/bin/env bash\nset -e\nexec `swiftup which $0` $@\n"
      let shims = Env["SWIFTUP_ROOT"]!.addingPath("shims/\(name)")
      try! script.write(toFile: shims, atomically: true, encoding: .utf8)
      run(program: "/bin/chmod", arguments: ["+x", shims])
    }

    for binary in binaries {
      createShims(name: binary)
    }
  }
}
