# Package

version       = "0.1.0"
author        = "oakes"
description   = "A parasitic editor"
license       = "Public Domain"
srcDir        = "src"
installExt    = @["dll", "so", "dylib"]
bin           = @["pvim"]



# Dependencies

requires "nim >= 1.0.6"
requires "paranim >= 0.2.0"
requires "pararules >= 0.1.0"
requires "https://github.com/paranim/paratext#e42512e"
