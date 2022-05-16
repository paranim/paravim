# Package

version       = "0.18.3"
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

requires "nim >= 1.2.6"
requires "paranim >= 0.12.0"
requires "pararules >= 1.1.0"
requires "paratext >= 0.13.0"
requires "illwill >= 0.2.0"
