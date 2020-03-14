# Package

version       = "0.2.0"
author        = "oakes"
description   = "A parasitic editor"
license       = "Public Domain"
srcDir        = "src"
installExt    = @[
  "nim", "txt", "ttf", "glsl",
  when defined(windows):
    "dll"
  elif defined(macosx):
    "dylib"
  elif defined(linux):
    "so"
]



# Dependencies

requires "nim >= 1.0.6"
requires "paranim >= 0.3.0"
requires "pararules >= 0.2.0"
requires "paratext >= 0.4.0"
