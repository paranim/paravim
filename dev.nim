import nimgl/glfw
from paranim/gl import nil
from paravim/core import nil
import paravim
from os import nil

when isMainModule:
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 1)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)
  glfwWindowHint(GLFWTransparentFramebuffer, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindowC(1024, 768, "Paravim", nil, nil)
  if w == nil:
    quit(-1)

  w.makeContextCurrent()
  glfwSwapInterval(1)

  discard w.setKeyCallback(keyCallback)
  discard w.setCharCallback(charCallback)
  discard w.setMouseButtonCallback(mouseButtonCallback)
  discard w.setCursorPosCallback(cursorPosCallback)
  discard w.setFramebufferSizeCallback(frameSizeCallback)

  var game = gl.RootGame()
  let params = os.commandLineParams()
  init(game, w, params)

  while not w.windowShouldClose:
    core.tick(game, true)
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
