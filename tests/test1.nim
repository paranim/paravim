# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import paravim/libvim
from paravim/vim import nil

vim.init(@[], nil, nil)

test "set the tab size":
  vimOptionSetTabSize(2)
  check vimOptionGetTabSize() == 2

test "read a line":
  let buf = vimBufferOpen("tests/hello.txt", 1, 0)
  check vimBufferGetLine(buf, 1) == "Hello, world!"
  vimExecute("bd!")

test "delete all lines":
  let buf = vimBufferOpen("tests/hello.txt", 1, 0)
  check vimBufferGetLine(buf, 1) == "Hello, world!"
  vim.onInput("g")
  vim.onInput("g")
  vim.onInput("d")
  vim.onInput("G")
  check vimBufferGetLine(buf, 1) == ""
  vim.onInput("p")
  check vimBufferGetLine(buf, 1) == "" # first line is blank
  check vimBufferGetLine(buf, 2) == "Hello, world!"
  echo "undoing"
  vim.onInput("u")
  vimExecute("bd!")
