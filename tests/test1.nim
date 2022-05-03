# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
from paranim/gl import nil
from paravim/libvim import nil
from paravim import nil
from paravim/vim import nil
import paranim/glfw

var game = gl.RootGame()

proc init() =
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindow(800, 600, "Paravim Test")
  if w == nil:
    quit(-1)

  w.makeContextCurrent()

  paravim.init(game, w)

init()

test "set the tab size":
  libvim.vimOptionSetTabSize(2)
  check libvim.vimOptionGetTabSize() == 2

test "read a line":
  let buf = libvim.vimBufferOpen("tests/hello.txt", 1, 0)
  check libvim.vimBufferGetLine(buf, 1) == "Hello, world!"
  libvim.vimExecute("bd!")

test "delete all lines":
  let buf = libvim.vimBufferOpen("tests/hello.txt", 1, 0)
  check libvim.vimBufferGetLine(buf, 1) == "Hello, world!"
  vim.onInput("g")
  vim.onInput("g")
  vim.onInput("d")
  vim.onInput("G")
  check libvim.vimBufferGetLine(buf, 1) == ""
  vim.onInput("p")
  check libvim.vimBufferGetLine(buf, 1) == "" # first line is blank
  check libvim.vimBufferGetLine(buf, 2) == "Hello, world!"
  vim.onInput("u")
  libvim.vimExecute("bd!")
