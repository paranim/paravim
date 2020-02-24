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
    MouseClick, MouseX, MouseY,
    FontSize, CurrentBufferId,
    BufferId, Lines, Path,
  CStrings = seq[cstring]

schema Fact(Id, Attr):
  WindowWidth: int
  WindowHeight: int
  MouseClick: int
  MouseX: float
  MouseY: float
  FontSize: float
  CurrentBufferId: int
  BufferId: int
  Lines: CStrings
  Path: cstring

let rules =
  ruleset:
    # getters
    rule getWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
    rule getFont(Fact):
      what:
        (Global, FontSize, fontSize)
    rule getCurrentBuffer(Fact):
      what:
        (Global, CurrentBufferId, cb)
        (id, BufferId, cb)
        (id, Lines, lines)

var
  session* = initSession(Fact)
  nextId* = Id.high.ord + 1

for r in rules.fields:
  session.add(r)

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
  session.insert(Global, FontSize, 1/4)
  session.insert(Global, CurrentBufferId, -1)

proc tick*(game: RootGame) =
  let (windowWidth, windowHeight) = session.query(rules.getWindow)
  let (fontSize) = session.query(rules.getFont)
  let currentBufferIndex = session.find(rules.getCurrentBuffer)

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  if currentBufferIndex >= 0:
    let currentBuffer = session.get(rules.getCurrentBuffer, currentBufferIndex)
    var e = deepCopy(text.monoEntity)
    for i in 0 ..< currentBuffer.lines.len:
      text.addLine(e, text.baseMonoEntity, text.monoFont, currentBuffer.lines[i])
    e.project(float(windowWidth), float(windowHeight))
    e.scale(fontSize, fontSize)
    render(game, e)
