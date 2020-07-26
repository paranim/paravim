# Package

version       = "0.16.1"
author        = "oakes"
description   = "A parasitic editor"
license       = "Public Domain"
srcDir        = "src"
installExt    = @[
  "nim", "txt", "ttf", "glsl", "c", "h",
  when defined(windows):
    "dll"
  elif defined(macosx):
    "dylib"
  elif defined(linux):
    "so"
]



# Dependencies

requires "nim >= 1.0.6"
requires "paranim >= 0.9.0"
requires "pararules >= 0.5.0"
requires "paratext >= 0.7.0"
