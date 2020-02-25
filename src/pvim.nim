import nimgl/glfw
from paranim/gl import nil
import pvimpkg/core
from pvimpkg/vim import nil
import tables
import bitops

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

proc keyCallback(window: GLFWWindow, key: int32, scancode: int32,
                 action: int32, mods: int32) {.cdecl.} =
  if action == GLFW_PRESS:
    let
      isControl = 0 != bitand(mods, GLFW_MOD_CONTROL)
      isShift = 0 != bitand(mods, GLFW_MOD_SHIFT)
    if isControl:
      if glfwToVimChars.hasKey(key):
        vim.onInput("<C-" & (if isShift: "S-" else: "") & glfwToVimChars[key] & ">")
    elif glfwToVimSpecials.hasKey(key):
      vim.onInput("<" & glfwToVimSpecials[key] & ">")

proc charCallback(window: GLFWWindow, codepoint: uint32) {.cdecl.} =
  vim.onInput("" & char(codepoint))

proc mouseButtonCallback(window: GLFWWindow, button: int32, action: int32, mods: int32) {.cdecl.} =
  if action == GLFWPress:
    onMouseClick(button)

proc cursorPosCallback(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  onMouseMove(xpos, ypos)

proc frameSizeCallback(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  onWindowResize(width, height)

when isMainModule:
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 1)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)
  glfwWindowHint(GLFWTransparentFramebuffer, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindow(1024, 768, "Paravim")
  if w == nil:
    quit(-1)

  vim.init(proc (buf: pointer; isForced: cint) {.cdecl.} = w.setWindowShouldClose(true))

  w.makeContextCurrent()
  glfwSwapInterval(1)

  discard w.setKeyCallback(keyCallback)
  discard w.setCharCallback(charCallback)
  discard w.setMouseButtonCallback(mouseButtonCallback)
  discard w.setCursorPosCallback(cursorPosCallback)
  discard w.setFramebufferSizeCallback(frameSizeCallback)
  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)
  w.frameSizeCallback(width, height)

  var game = gl.RootGame()
  game.init()

  while not w.windowShouldClose:
    game.tick()
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
