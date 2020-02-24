import nimgl/glfw
from paranim/gl import nil
import pvimpkg/core
from pvimpkg/vim import nil

proc keyCallback(window: GLFWWindow, key: int32, scancode: int32,
                 action: int32, mods: int32): void {.cdecl.} =
  if action == GLFW_PRESS:
    if key == GLFWKey.Escape:
      window.setWindowShouldClose(true)
    else:
      keyPressed(key)
  elif action == GLFW_RELEASE:
    keyReleased(key)

proc mouseButtonCallback(window: GLFWWindow, button: int32, action: int32, mods: int32): void {.cdecl.} =
  if action == GLFWPress:
    mouseClicked(button)

proc cursorPosCallback(window: GLFWWindow, xpos: float64, ypos: float64): void {.cdecl.} =
  mouseMoved(xpos, ypos)

proc frameSizeCallback(window: GLFWWindow, width: int32, height: int32): void {.cdecl.} =
  windowResized(width, height)

when isMainModule:
  vim.init()

  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 1)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindow(800, 600, "Paravim")
  if w == nil:
    quit(-1)

  w.makeContextCurrent()
  glfwSwapInterval(1)

  discard w.setKeyCallback(keyCallback)
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
