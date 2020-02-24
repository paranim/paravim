import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
import paratext, paratext/gl/text
import pararules
import sets
from math import `mod`

const
  monoFontRaw = staticRead("../assets/ttf/FiraCode-Regular.ttf")
  variFontRaw = staticRead("../assets/ttf/Roboto-Regular.ttf")

let
  monoFont = initFont(ttf = monoFontRaw, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)
  variFont = initFont(ttf = variFontRaw, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)

var
  baseMonoEntity: UncompiledTextEntity
  monoEntity: InstancedTextEntity

proc add(instancedEntity: var InstancedTextEntity, entity: UncompiledTextEntity, font: Font, text: cstring) =
  var
    x = 0f
    i = 0
  for ch in text:
    let
      charIndex = int(ch) - font.firstChar
      bakedChar = font.chars[charIndex]
    var e = entity
    e.crop(bakedChar, x, font.baseline)
    if i == instancedEntity.instanceCount:
      instancedEntity.add(e)
    else:
      instancedEntity[i] = e
    x += bakedChar.xadvance
    i += 1

type
  Game* = object of RootGame
    deltaTime*: float
    totalTime*: float
  Id* = enum
    Global
  Attr* = enum
    WindowWidth, WindowHeight,
    PressedKeys, MouseClick, MouseX, MouseY,
    Lines,
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

proc init*(game: var Game) =
  # opengl
  doAssert glInit()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # init fonts
  baseMonoEntity = initTextEntity(monoFont)
  let
    uncompiledMonoEntity = initInstancedEntity(baseMonoEntity)
    compiledMonoEntity = compile(game, uncompiledMonoEntity)
  monoEntity = deepCopy(compiledMonoEntity)

  # set initial values
  session.insert(Global, PressedKeys, initHashSet[int]())

proc tick*(game: Game) =
  let (windowWidth, windowHeight) = session.query(rules.getWindow)
  let (lines) = session.query(rules.getLines)

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  for i in 0 ..< lines.len:
    var e = deepCopy(monoEntity)
    e.add(baseMonoEntity, monoFont, lines[i])
    e.project(float(windowWidth), float(windowHeight))
    e.translate(0f, i.cfloat * monoFont.height)
    render(game, e)
