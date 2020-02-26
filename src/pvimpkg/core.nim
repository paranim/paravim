import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
from paranim/primitives import nil
from paranim/math as pmath import translate
import pararules
from text import nil
from paratext/gl/text as ptext import nil
from buffers import BufferUpdateTuple
import sets
from math import `mod`
from glm import nil
from libvim import nil

const
  bgColor = glm.vec4(GLfloat(52/255), GLfloat(40/255), GLfloat(42/255), GLfloat(0.95))
  textColor = glm.vec4(1f, 1f, 1f, 1f)
  cursorColor = glm.vec4(GLfloat(112/255), GLfloat(128/255), GLfloat(144/255), GLfloat(0.9))
  tanColor = glm.vec4(GLfloat(209/255), GLfloat(153/255), GLfloat(101/255), GLfloat(1))
  completionColor = glm.vec4(GLfloat(52/255), GLfloat(40/255), GLfloat(42/255), GLfloat(0.65))
  fontSizeStep = 1/16
  minFontSize = 1/8
  maxFontSize = 1

type
  Id* = enum
    Global
  Attr* = enum
    WindowWidth, WindowHeight,
    MouseClick, MouseX, MouseY,
    FontSize, CurrentBufferId, BufferUpdate,
    VimMode, VimCommandText, VimCommandStart,
    VimCommandPosition, VimCommandCompletion,
    BufferId, Lines, Path,
    CursorLine, CursorColumn, ScrollX, ScrollY,
    LineCount,
  Strings = seq[string]

schema Fact(Id, Attr):
  WindowWidth: int
  WindowHeight: int
  MouseClick: int
  MouseX: float
  MouseY: float
  FontSize: float
  CurrentBufferId: int
  BufferUpdate: BufferUpdateTuple
  VimMode: int
  VimCommandText: string
  VimCommandStart: string
  VimCommandPosition: int
  VimCommandCompletion: string
  BufferId: int
  Lines: Strings
  Path: string
  CursorLine: int
  CursorColumn: int
  ScrollX: float
  ScrollY: float
  LineCount: int

let rules* =
  ruleset:
    rule getWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
    rule getFont(Fact):
      what:
        (Global, FontSize, fontSize)
    rule getVim(Fact):
      what:
        (Global, VimMode, mode)
        (Global, VimCommandText, commandText)
        (Global, VimCommandStart, commandStart)
        (Global, VimCommandPosition, commandPosition)
        (Global, VimCommandCompletion, commandCompletion)
    rule getCurrentBuffer(Fact):
      what:
        (Global, CurrentBufferId, cb)
        (id, BufferId, cb)
        (id, Lines, lines)
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX)
        (id, ScrollY, scrollY)
    rule getBuffer(Fact):
      what:
        (id, BufferId, bufferId)
    rule onBufferUpdate(Fact):
      what:
        (Global, BufferUpdate, bu)
        (id, Lines, lines)
        (id, BufferId, bufferId)
      cond:
        bufferId == bu.bufferId
      then:
        session.retract(Global, BufferUpdate, bu)
        session.insert(id, Lines, buffers.updateLines(lines, bu))
    rule onWindowResize(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
      then:
        let
          textWidth = text.monoFont.chars[0].xadvance * fontSize
          textHeight = text.monoFont.height * fontSize
        libvim.vimWindowSetWidth(int32(windowWidth.float / textWidth))
        libvim.vimWindowSetHeight(int32(windowHeight.float / textHeight))
    rule updateLineCount(Fact):
      what:
        (id, Lines, lines)
        (id, LineCount, lineCount, then = false)
      cond:
        lines.len != lineCount
      then:
        session.insert(id, LineCount, lines.len)
    rule updateScrollX(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, FontSize, fontSize)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX, then = false)
      then:
        let
          textWidth = text.monoFont.chars[0].xadvance * fontSize
          cursorLeft = cursorColumn.float * textWidth
          cursorRight = cursorLeft + textWidth
          textViewWidth = windowWidth.float
          scrollRight = scrollX + textViewWidth
        if cursorLeft < scrollX:
          session.insert(id, ScrollX, cursorLeft)
        elif cursorRight > scrollRight:
          session.insert(id, ScrollX, cursorRight - textViewWidth)
    rule updateScrollY(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
        (id, CursorLine, cursorLine)
        (id, ScrollY, scrollY, then = false)
        (id, LineCount, lineCount)
      then:
        let
          textHeight = text.monoFont.height * fontSize
          cursorTop = cursorLine.float * textHeight
          cursorBottom = cursorTop + textHeight
          textViewHeight = windowHeight.float - textHeight
          scrollBottom = scrollY + textViewHeight
          documentBottom = lineCount.float * textHeight
        if documentBottom > textViewHeight and scrollY + textViewHeight > documentBottom:
          session.insert(id, ScrollY, documentBottom - textViewHeight)
        elif cursorTop < scrollY:
          session.insert(id, ScrollY, cursorTop)
        elif cursorBottom > scrollBottom and scrollBottom > 0:
          session.insert(id, ScrollY, cursorBottom - textViewHeight)

var
  session* = initSession(Fact)
  nextId* = Id.high.ord + 1
  baseMonoEntity: ptext.UncompiledTextEntity
  monoEntity: text.ParavimTextEntity
  rectEntity: TwoDEntity

proc getCurrentSessionId*(): int =
  let index = session.find(rules.getCurrentBuffer)
  if index >= 0:
    session.get(rules.getCurrentBuffer, index).id
  else:
    -1

proc getSessionId*(bufferId: int): int =
  let index = session.find(rules.getBuffer, bufferId = bufferId)
  if index >= 0:
    session.get(rules.getBuffer, index).id
  else:
    -1

for r in rules.fields:
  session.add(r)

proc onMouseClick*(button: int) =
  session.insert(Global, MouseClick, button)

proc onMouseMove*(xpos: float, ypos: float) =
  session.insert(Global, MouseX, xpos)
  session.insert(Global, MouseY, ypos)

proc onWindowResize*(width: int, height: int) =
  if width == 0 or height == 0:
    return
  session.insert(Global, WindowWidth, width)
  session.insert(Global, WindowHeight, height)

proc fontDec*() =
  let
    (fontSize) = session.query(rules.getFont)
    newFontSize = fontSize - fontSizeStep
  if newFontSize >= minFontSize:
    session.insert(Global, FontSize, newFontSize)

proc fontInc*() =
  let
    (fontSize) = session.query(rules.getFont)
    newFontSize = fontSize + fontSizeStep
  if newFontSize <= maxFontSize:
    session.insert(Global, FontSize, newFontSize)

proc init*(game: var RootGame) =
  # opengl
  doAssert glInit()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # init entities
  baseMonoEntity = ptext.initTextEntity(text.monoFont)
  let uncompiledMonoEntity = text.initInstancedEntity(baseMonoEntity, text.monoFont)
  monoEntity = compile(game, uncompiledMonoEntity)
  rectEntity = compile(game, initTwoDEntity(primitives.rectangle[GLfloat]()))

  # set initial values
  session.insert(Global, FontSize, 1/4)

proc tick*(game: RootGame) =
  let
    (windowWidth, windowHeight) = session.query(rules.getWindow)
    (fontSize) = session.query(rules.getFont)
    vim = session.query(rules.getVim)
    currentBufferIndex = session.find(rules.getCurrentBuffer)
    fontWidth = text.monoFont.chars[0].xadvance
    textWidth = fontWidth * fontSize
    textHeight = text.monoFont.height * fontSize

  glClearColor(bgColor.arr[0], bgColor.arr[1], bgColor.arr[2], bgColor.arr[3])
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  if currentBufferIndex >= 0:
    let currentBuffer = session.get(rules.getCurrentBuffer, currentBufferIndex)
    var camera = glm.mat3f(1)
    camera.translate(currentBuffer.scrollX, currentBuffer.scrollY)

    # cursor
    if vim.mode != libvim.CommandLine.ord:
      var e = rectEntity
      e.project(float(windowWidth), float(windowHeight))
      e.invert(camera)
      e.translate(currentBuffer.cursorColumn.GLfloat * textWidth, currentBuffer.cursorLine.GLfloat * textHeight)
      e.scale(if vim.mode == libvim.Insert.ord: textWidth / 4 else: textWidth, textHeight)
      e.color(cursorColor)
      render(game, e)

    # text
    block:
      let
        linesToSkip = int(currentBuffer.scrollY / textHeight)
        visibleLines = int(windowHeight.float / textHeight) + 1
      var e = deepCopy(monoEntity)
      e.uniforms.u_start_line.data = linesToSkip.int32
      e.uniforms.u_start_line.disable = false
      for i in linesToSkip ..< linesToSkip + visibleLines:
        if i >= currentBuffer.lines.len:
          break
        discard text.addLine(e, baseMonoEntity, text.monoFont, textColor, currentBuffer.lines[i])
      e.project(float(windowWidth), float(windowHeight))
      e.invert(camera)
      e.scale(fontSize, fontSize)
      render(game, e)

  # command line background
  block:
    var e = rectEntity
    e.project(float(windowWidth), float(windowHeight))
    e.translate(0f, float(windowHeight) - textHeight)
    e.scale(float(windowWidth), textHeight)
    e.color(if vim.mode == libvim.CommandLine.ord: tanColor else: bgColor)
    render(game, e)
  if vim.mode == libvim.CommandLine.ord:
    # command line cursor
    block:
      var e = rectEntity
      e.project(float(windowWidth), float(windowHeight))
      e.translate((vim.commandPosition.float + 1) * textWidth, float(windowHeight) - textHeight)
      e.scale(textWidth / 4, textHeight)
      e.color(cursorColor)
      render(game, e)
    # command line text
    block:
      var e = deepCopy(monoEntity)
      e.uniforms.u_start_line.data = 0
      e.uniforms.u_start_line.disable = false
      let endPos = text.addLine(e, baseMonoEntity, text.monoFont, bgColor, vim.commandStart & vim.commandText)
      if vim.commandCompletion != "":
        let
          compLen = vim.commandCompletion.len
          commLen = vim.commandText.len
        if compLen > commLen:
          discard text.add(e, baseMonoEntity, text.monoFont, completionColor, vim.commandCompletion[commLen ..< compLen], endPos)
      e.project(float(windowWidth), float(windowHeight))
      e.translate(0f, float(windowHeight) - textHeight)
      e.scale(fontSize, fontSize)
      render(game, e)
