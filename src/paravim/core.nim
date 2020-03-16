import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
from paranim/primitives import nil
from paranim/math as pmath import translate
import pararules
from text import ParavimTextEntity
from paratext/gl/text as ptext import nil
from buffers import BufferUpdateTuple, RangeTuple
import colors
import sets
from math import `mod`
from glm import nil
from libvim import nil
import tables
from strutils import nil
from times import nil
from tree_sitter import nil

const
  fontSizeStep = 1/16
  minFontSize = 1/8
  maxFontSize = 1
  asciiArt* = {"smile": strutils.splitLines(staticRead("assets/ascii/smile.txt")),
               "intro": strutils.splitLines(staticRead("assets/ascii/intro.txt")),
               "cat": strutils.splitLines(staticRead("assets/ascii/cat.txt")),
               "usa": strutils.splitLines(staticRead("assets/ascii/usa.txt")),
               "christmas": strutils.splitLines(staticRead("assets/ascii/christmas.txt"))}.toTable

type
  Id* = enum
    Global
  Attr* = enum
    WindowTitle, WindowTitleCallback,
    WindowWidth, WindowHeight,
    MouseClick, MouseX, MouseY,
    FontSize, CurrentBufferId, BufferUpdate,
    VimMode, VimCommandText, VimCommandStart,
    VimCommandPosition, VimCommandCompletion,
    VimVisualRange, VimSearchRanges, VimShowSearch,
    AsciiArt, DeleteBuffer,
    BufferId, Lines, Path,
    CursorLine, CursorColumn, ScrollX, ScrollY,
    LineCount, Tree, FullText, CroppedText
  Strings = seq[string]
  RangeTuples = seq[RangeTuple]
  WindowTitleCallbackType = proc (title: string)

schema Fact(Id, Attr):
  WindowTitle: string
  WindowTitleCallback: WindowTitleCallbackType
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
  VimVisualRange: RangeTuple
  VimSearchRanges: RangeTuples
  VimShowSearch: bool
  AsciiArt: string
  DeleteBuffer: int
  BufferId: int
  Lines: Strings
  Path: string
  CursorLine: int
  CursorColumn: int
  ScrollX: float
  ScrollY: float
  LineCount: int
  Tree: pointer
  FullText: ParavimTextEntity
  CroppedText: ParavimTextEntity

var
  session* = initSession(Fact)
  nextId* = Id.high.ord + 1
  baseMonoEntity: ptext.UncompiledTextEntity
  monoEntity: ParavimTextEntity
  uncompiledRectEntity: UncompiledTwoDEntity
  rectEntity: TwoDEntity
  rectsEntity: InstancedTwoDEntity

let rules* =
  ruleset:
    rule windowTitleCallback(Fact):
      what:
        (Global, WindowTitle, title)
        (Global, WindowTitleCallback, callback)
      then:
        callback(title)
    rule getWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
        (Global, AsciiArt, ascii)
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
        (Global, VimVisualRange, visualRange)
        (Global, VimSearchRanges, searchRanges)
        (Global, VimShowSearch, showSearch)
    rule getCurrentBuffer(Fact):
      what:
        (Global, CurrentBufferId, bufferId)
        (id, BufferId, bufferId)
        (id, Lines, lines)
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX)
        (id, ScrollY, scrollY)
        (id, LineCount, lineCount)
        (id, Tree, tree)
        (id, FullText, fullText)
        (id, CroppedText, croppedText)
    rule getBuffer(Fact):
      what:
        (id, BufferId, bufferId)
        (id, Lines, lines)
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX)
        (id, ScrollY, scrollY)
        (id, LineCount, lineCount)
        (id, Tree, tree)
        (id, FullText, fullText)
        (id, CroppedText, croppedText)
    rule deleteBuffer(Fact):
      what:
        (Global, DeleteBuffer, bufferId)
        (id, BufferId, bufferId)
        (id, Lines, lines)
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX)
        (id, ScrollY, scrollY)
        (id, LineCount, lineCount)
        (id, Tree, tree)
        (id, FullText, fullText)
        (id, CroppedText, croppedText)
      then:
        session.retract(id, BufferId, bufferId)
        session.retract(id, Lines, lines)
        session.retract(id, CursorLine, cursorLine)
        session.retract(id, CursorColumn, cursorColumn)
        session.retract(id, ScrollX, scrollX)
        session.retract(id, ScrollY, scrollY)
        session.retract(id, LineCount, lineCount)
        session.retract(id, Tree, tree)
        session.retract(id, FullText, fullText)
        session.retract(id, CroppedText, croppedText)
    rule updateBuffer(Fact):
      what:
        (Global, BufferUpdate, bu)
        (id, Lines, lines)
        (id, BufferId, bufferId)
      cond:
        bufferId == bu.bufferId
      then:
        session.retract(Global, BufferUpdate, bu)
        session.insert(id, Lines, buffers.updateLines(lines, bu))
    rule resizeWindow(Fact):
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
    rule updateFullText(Fact):
      what:
        (id, Tree, tree)
        (id, Lines, lines)
      then:
        let parsed = tree_sitter.parse(tree)
        var e = deepCopy(monoEntity)
        for i in 0 ..< lines.len:
          discard text.addLine(e, baseMonoEntity, text.monoFont, textColor, lines[i], if parsed.hasKey(i): parsed[i] else: @[])
        session.insert(id, FullText, e)
    rule updateCroppedText(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
        (id, FullText, fullText)
        (id, LineCount, lineCount)
        (id, ScrollY, scrollY)
      then:
        var e = fullText
        let
          fontHeight = text.monoFont.height
          textHeight = fontHeight * fontSize
          linesToSkip = min(int(scrollY / textHeight), lineCount)
          linesToCrop = min(linesToSkip + int(windowHeight.float / textHeight) + 1, lineCount)
          (charsToSkip, charsToCrop, charCounts) = buffers.getVisibleChars(e, linesToSkip, linesToCrop)
        e.uniforms.u_char_counts.data = charCounts
        e.uniforms.u_char_counts.disable = false
        e.uniforms.u_start_line.data = linesToSkip.int32
        e.uniforms.u_start_line.disable = false
        text.crop(e, charsToSkip, charsToCrop)
        session.insert(id, CroppedText, e)

proc getCurrentSessionId*(): int =
  let index = session.find(rules.getCurrentBuffer)
  if index >= 0:
    session.get(rules.getCurrentBuffer, index).id
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

proc init*(game: var RootGame, showAscii: bool, density: float) =
  # opengl
  doAssert glInit()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # init entities
  baseMonoEntity = ptext.initTextEntity(text.monoFont)
  let uncompiledMonoEntity = text.initInstancedEntity(baseMonoEntity, text.monoFont)
  monoEntity = compile(game, uncompiledMonoEntity)
  uncompiledRectEntity = initTwoDEntity(primitives.rectangle[GLfloat]())
  rectEntity = compile(game, uncompiledRectEntity)
  rectsEntity = compile(game, initInstancedEntity(uncompiledRectEntity))

  # set initial values
  session.insert(Global, FontSize, 1/4 * density)
  let ascii =
    if showAscii:
      let
        date = times.now()
        md = (date.month, date.monthday.ord)
      if md == (times.mAug, 8): "cat"
      elif md == (times.mJul, 4): "usa"
      elif md == (times.mDec, 25): "christmas"
      else: "intro"
    else:
      ""
  session.insert(Global, AsciiArt, ascii)

proc tick*(game: RootGame, clear: bool) =
  let
    (windowWidth, windowHeight, ascii) = session.query(rules.getWindow)
    (fontSize) = session.query(rules.getFont)
    vim = session.query(rules.getVim)
    currentBufferIndex = session.find(rules.getCurrentBuffer)
    fontWidth = text.monoFont.chars[0].xadvance
    fontHeight = text.monoFont.height
    textWidth = fontWidth * fontSize
    textHeight = fontHeight * fontSize

  if clear:
    glClearColor(bgColor.arr[0], bgColor.arr[1], bgColor.arr[2], bgColor.arr[3])
    glClear(GL_COLOR_BUFFER_BIT)
  else:
    var e = rectEntity
    e.project(float(windowWidth), float(windowHeight))
    e.translate(0f, 0f)
    e.scale(float(windowWidth), float(windowHeight))
    e.color(bgColor)
    render(game, e)

  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  if ascii != "":
    var e = deepCopy(monoEntity)
    e.uniforms.u_start_line.data = 0
    e.uniforms.u_start_line.disable = false
    for line in asciiArt[ascii]:
      discard text.addLine(e, baseMonoEntity, text.monoFont, asciiColor, line, [])
    e.project(float(windowWidth), float(windowHeight))
    e.scale(fontSize, fontSize)
    render(game, e)
  elif currentBufferIndex >= 0:
    let currentBuffer = session.get(rules.getCurrentBuffer, currentBufferIndex)
    var camera = glm.mat3f(1)
    camera.translate(currentBuffer.scrollX, currentBuffer.scrollY)
    block:
      var e = deepCopy(rectsEntity)
      # cursor
      if vim.mode != libvim.CommandLine.ord:
        var e2 = uncompiledRectEntity
        e2.project(float(windowWidth), float(windowHeight))
        e2.invert(camera)
        e2.translate(currentBuffer.cursorColumn.GLfloat * textWidth, currentBuffer.cursorLine.GLfloat * textHeight)
        e2.scale(if vim.mode == libvim.Insert.ord: textWidth / 4 else: textWidth, textHeight)
        e2.color(cursorColor)
        e.add(e2)
      # selection
      if vim.visualRange != (0, 0, 0, 0):
        let rects = buffers.rangeToRects(buffers.normalizeRange(vim.visualRange), currentBuffer.lines)
        for (left, top, width, height) in rects:
          var e2 = uncompiledRectEntity
          e2.project(float(windowWidth), float(windowHeight))
          e2.invert(camera)
          e2.scale(textWidth, textHeight)
          e2.translate(left, top)
          e2.scale(width, height)
          e2.color(selectColor)
          e.add(e2)
      # search
      if vim.showSearch:
        for highlight in vim.searchRanges:
          let rects = buffers.rangeToRects(highlight, currentBuffer.lines)
          for (left, top, width, height) in rects:
            var e2 = uncompiledRectEntity
            e2.project(float(windowWidth), float(windowHeight))
            e2.invert(camera)
            e2.scale(textWidth, textHeight)
            e2.translate(left, top)
            e2.scale(width, height)
            e2.color(searchColor)
            e.add(e2)
      if e.instanceCount > 0:
        render(game, e)
    # text
    block:
      var e = currentBuffer.croppedText
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
      let endPos = text.addLine(e, baseMonoEntity, text.monoFont, bgColor, vim.commandStart & vim.commandText, [])
      if vim.commandCompletion != "":
        let
          compLen = vim.commandCompletion.len
          commLen = vim.commandText.len
        if compLen > commLen:
          discard text.add(e, baseMonoEntity, text.monoFont, completionColor, vim.commandCompletion[commLen ..< compLen], [], endPos)
      e.project(float(windowWidth), float(windowHeight))
      e.translate(0f, float(windowHeight) - textHeight)
      e.scale(fontSize, fontSize)
      render(game, e)
