import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
import pararules
import sets
from math import `mod`

type
  Game* = object of RootGame
    deltaTime*: float
    totalTime*: float
  Id = enum
    Global
  Attr = enum
    WindowWidth, WindowHeight,
    PressedKeys, MouseClick, MouseX, MouseY,
  IntSet = HashSet[int]

schema Fact(Id, Attr):
  WindowWidth: int
  WindowHeight: int
  PressedKeys: IntSet
  MouseClick: int
  MouseX: float
  MouseY: float

let rules =
  ruleset:
    # getters
    rule getWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
    rule getKeys(Fact):
      what:
        (Global, PressedKeys, keys)

var session = initSession(Fact)

for r in rules.fields:
  session.add(r)

proc keyPressed*(key: int) =
  var (keys) = session.query(rules.getKeys)
  keys.incl(key)
  session.insert(Global, PressedKeys, keys)

proc keyReleased*(key: int) =
  var (keys) = session.query(rules.getKeys)
  keys.excl(key)
  session.insert(Global, PressedKeys, keys)

proc mouseClicked*(button: int) =
  session.insert(Global, MouseClick, button)

proc mouseMoved*(xpos: float, ypos: float) =
  session.insert(Global, MouseX, xpos)
  session.insert(Global, MouseY, ypos)

proc windowResized*(width: int, height: int) =
  if width == 0 or height == 0:
    return
  session.insert(Global, WindowWidth, width)
  session.insert(Global, WindowHeight, height)

proc init*(game: var Game) =
  # opengl
  doAssert glInit()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # set initial values
  session.insert(Global, PressedKeys, initHashSet[int]())

proc tick*(game: Game) =
  let (windowWidth, windowHeight) = session.query(rules.getWindow)

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))
