import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
from paranim/primitives import nil
import pararules
from text import nil
import sets
from math import `mod`
from glm import nil

type
  Id* = enum
    Global
  Attr* = enum
    WindowWidth, WindowHeight,
    MouseClick, MouseX, MouseY,
    FontSize, CurrentBufferId,
    BufferId, Lines, Path,
    CursorLine, CursorColumn,
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
  CursorLine: int
  CursorColumn: int

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
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)

var
  session* = initSession(Fact)
  nextId* = Id.high.ord + 1
  cursorEntity: TwoDEntity

proc getCurrentBufferId*(): int =
  let index = session.find(rules.getCurrentBuffer)
  if index >= 0:
    session.get(rules.getCurrentBuffer, index).id
  else:
    -1

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

  # init cursor
  cursorEntity = compile(game, initTwoDEntity(primitives.rectangle[GLfloat]()))

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

    let fontWidth = text.monoFont.chars[115 - text.monoFont.firstChar].xadvance
    var e2 = cursorEntity
    e2.project(float(windowWidth), float(windowHeight))
    e2.scale(fontWidth * fontSize, text.monoFont.height * fontSize)
    e2.translate(currentBuffer.cursorColumn.GLfloat, currentBuffer.cursorLine.GLfloat)
    e2.color(glm.vec4(GLfloat(112/255), GLfloat(128/255), GLfloat(144/255), GLfloat(0.9)))
    render(game, e2)
