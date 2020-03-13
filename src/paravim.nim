import nimgl/glfw
from paranim/gl import nil
from paravim/core import nil
from paravim/vim import nil
from paravim/libvim import nil
import tables
import bitops
from os import nil

const glfwToVimSpecials =
  {GLFWKey.BACKSPACE: "BS",
   GLFWKey.DELETE: "Del",
   GLFWKey.TAB: "Tab",
   GLFWKey.ENTER: "Enter",
   GLFWKey.ESCAPE: "Esc",
   GLFWKey.UP: "Up",
   GLFWKey.DOWN: "Down",
   GLFWKey.LEFT: "Left",
   GLFWKey.RIGHT: "Right",
   GLFWKey.HOME: "Home",
   GLFWKey.END: "End",
   GLFWKey.PAGE_UP: "PageUp",
   GLFWKey.PAGE_DOWN: "PageDown"}.toTable

const glfwToVimChars =
  {GLFWKey.D: "D",
   GLFWKey.H: "H",
   GLFWKey.J: "J",
   GLFWKey.M: "M",
   GLFWKey.P: "P",
   GLFWKey.R: "R",
   GLFWKey.U: "U"}.toTable

proc keyCallback*(window: GLFWWindow, key: int32, scancode: int32,
                  action: int32, mods: int32) {.cdecl.} =
  if action == GLFW_PRESS:
    let
      isControl = 0 != bitand(mods, GLFW_MOD_CONTROL)
      isShift = 0 != bitand(mods, GLFW_MOD_SHIFT)
    if isControl:
      if key == GLFWKey.Minus:
        core.fontDec()
      elif key == GLFWKey.Equal:
        core.fontInc()
      elif glfwToVimChars.hasKey(key):
        vim.onInput("<C-" & (if isShift: "S-" else: "") & glfwToVimChars[key] & ">")
    elif glfwToVimSpecials.hasKey(key):
      vim.onInput("<" & glfwToVimSpecials[key] & ">")

proc charCallback*(window: GLFWWindow, codepoint: uint32) {.cdecl.} =
  vim.onInput("" & char(codepoint))

proc mouseButtonCallback*(window: GLFWWindow, button: int32, action: int32, mods: int32) {.cdecl.} =
  if action == GLFWPress:
    core.onMouseClick(button)

proc cursorPosCallback*(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  core.onMouseMove(xpos, ypos)

proc frameSizeCallback*(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  core.onWindowResize(width, height)

proc init*(game: var gl.RootGame, w: GLFWWindow, params: seq[string]) =
  vim.init(params, proc (buf: pointer; isForced: cint) {.cdecl.} = quit(0))

  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)
  w.frameSizeCallback(width, height)

  var windowWidth, windowHeight: int32
  w.getWindowSize(windowWidth.addr, windowHeight.addr)
  let density = max(1, int(width / windowWidth))

  core.init(game, params.len == 0, float(density))

proc init*(game: var gl.RootGame, w: GLFWWindow) =
  init(game, w, @[])

proc tick*(game: gl.RootGame) =
  core.tick(game, false)

proc isNormalMode*(): bool =
  libvim.vimGetMode() in {libvim.Normal.ord, libvim.NormalBusy.ord}
