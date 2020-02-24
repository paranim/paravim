import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
import pararules
from text import nil
import sets
from math import `mod`

type
  Id* = enum
    Global
  Attr* = enum
    WindowWidth, WindowHeight,
    PressedKeys, MouseClick, MouseX, MouseY,
    Lines, FontSize,
  IntSet = HashSet[int]
  CStrings = seq[cstring]

schema Fact(Id, Attr):
  WindowWidth: int
  WindowHeight: int
  PressedKeys: IntSet
  MouseClick: int
  MouseX: float
  MouseY: float
  Lines: CStrings
  FontSize: float

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
    rule getLines(Fact):
      what:
        (Global, Lines, lines)
    rule getFont(Fact):
      what:
        (Global, FontSize, fontSize)

var session* = initSession(Fact)

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

proc init*(game: var RootGame) =
  # opengl
  doAssert glInit()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # init fonts
  text.init(game)

  # set initial values
  session.insert(Global, PressedKeys, initHashSet[int]())
  session.insert(Global, FontSize, 1/4)

proc tick*(game: RootGame) =
  let (windowWidth, windowHeight) = session.query(rules.getWindow)
  let (lines) = session.query(rules.getLines)
  let (fontSize) = session.query(rules.getFont)

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  for i in 0 ..< lines.len:
    var e = deepCopy(text.monoEntity)
    text.add(e, text.baseMonoEntity, text.monoFont, lines[i])
    e.project(float(windowWidth), float(windowHeight))
    e.translate(0f, i.cfloat * text.monoFont.height * fontSize)
    e.scale(fontSize, fontSize)
    render(game, e)
