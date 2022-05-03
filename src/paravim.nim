import paranim/glfw
from paranim/gl import nil
from paravim/core import nil
from paravim/vim import nil
from paravim/libvim import nil
from paravim/structs import nil
from pararules import nil
import tables
import bitops
from os import nil
from strutils import nil

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
   GLFWKey.U: "U",
   GLFWKey.V: "V"}.toTable

proc keyCallback*(window: GLFWWindow, key: int32, scancode: int32,
                  action: int32, mods: int32) {.cdecl.} =
  if key < 0:
    return
  if action == GLFW_PRESS:
    let
      isControl = 0 != bitand(mods, GLFW_MOD_CONTROL)
      isShift = 0 != bitand(mods, GLFW_MOD_SHIFT)
    if isControl:
      if key == GLFWKey.Minus:
        core.fontDec()
      elif key == GLFWKey.Equal:
        core.fontInc()
      elif key == GLFWKey.V:
        if libvim.vimGetMode() == libvim.Insert.ord:
          vim.onBulkInput($ window.getClipboardString())
        else:
          vim.onInput("<C-V>")
      elif glfwToVimChars.hasKey(key):
        vim.onInput("<C-" & (if isShift: "S-" else: "") & glfwToVimChars[key] & ">")
    elif glfwToVimSpecials.hasKey(key):
      vim.onInput("<" & glfwToVimSpecials[key] & ">")
  elif action == GLFW_REPEAT:
    if glfwToVimSpecials.hasKey(key):
      vim.onInput("<" & glfwToVimSpecials[key] & ">")

proc charCallback*(window: GLFWWindow, codepoint: uint32) {.cdecl.} =
  vim.onInput($ char(codepoint))

proc mouseButtonCallback*(window: GLFWWindow, button: int32, action: int32, mods: int32) {.cdecl.} =
  if action == GLFWPress:
    core.onMouseClick(button)

var density: float

proc cursorPosCallback*(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  if density == 0:
    return # we can't move the mouse until we know the screen density
  core.onMouseMove(xpos * density, ypos * density)

proc frameSizeCallback*(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  core.onWindowResize(width, height)

proc scrollCallback*(window: GLFWWindow, xoffset: float64, yoffset: float64) {.cdecl.} =
  if density == 0:
    return # we can't scroll until we know the screen density
  core.onScroll(xoffset / density, yoffset / density)

var
  window: GLFWWindow # this is necessary because cdecl functions can't capture local variables
  totalTime: float

proc init*(game: var gl.RootGame, w: GLFWWindow, params: seq[string]) =
  window = w

  proc onQuit(buf: pointer; isForced: cint) {.cdecl.} =
    window.setWindowShouldClose(true)

  proc onYank(yankInfo: ptr structs.yankInfo_T) {.cdecl.} =
    let
      lines = cstringArrayToSeq(cast[cstringArray](yankInfo.lines), yankInfo.numLines)
      content = strutils.join(lines, "\n")
    window.setClipboardString(content)

  vim.init(onQuit, onYank)

  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)
  w.frameSizeCallback(width, height)

  var windowWidth, windowHeight: int32
  w.getWindowSize(windowWidth.addr, windowHeight.addr)
  density = max(1, int(width / windowWidth)).float

  core.init(game, params.len == 0, density)
  core.windowTitleCallback = proc (title: string) = w.setWindowTitle(title)
  totalTime = glfwGetTime()

  for fname in params:
    discard libvim.vimBufferOpen(fname, 1, 0)

proc init*(game: var gl.RootGame, w: GLFWWindow) =
  init(game, w, @[])

proc tick*(game: gl.RootGame, clear: bool): bool =
  let
    ts = glfwGetTime()
    deltaTime = ts - totalTime
  totalTime = ts
  core.insert(core.session, core.Global, core.DeltaTime, deltaTime)
  pararules.fireRules(core.session)
  result = core.tick(game, clear)

proc tick*(game: gl.RootGame): bool =
  tick(game, false)

proc isNormalMode*(): bool =
  libvim.vimGetMode() in {libvim.Normal.ord, libvim.NormalBusy.ord}
