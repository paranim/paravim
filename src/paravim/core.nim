import nimgl/opengl
from nimgl/glfw import GLFWKey
import paranim/gl, paranim/gl/entities
from paranim/primitives import nil
from paranim/math as pmath import translate
import pararules
from text import ParavimTextEntity
from paratext/gl/text as ptext import nil
from buffers import RangeTuple, BufferUpdateTuple
import colors
import sets
from math import `mod`
from glm import nil
from libvim import nil
from structs import nil
import tables
from strutils import nil
import times
from tree_sitter import Nodes
from scroll import nil
from sequtils import nil

const
  fontSizeStep = 1/16
  minFontSize = 1/8
  maxFontSize = 1
  defaultFontSize = 1/4
  asciiArt* = {"smile": strutils.splitLines(staticRead("assets/ascii/smile.txt")),
               "intro": strutils.splitLines(staticRead("assets/ascii/intro.txt")),
               "cat": strutils.splitLines(staticRead("assets/ascii/cat.txt")),
               "usa": strutils.splitLines(staticRead("assets/ascii/usa.txt")),
               "christmas": strutils.splitLines(staticRead("assets/ascii/christmas.txt"))}.toTable

type
  Id* = enum
    Global
  Attr* = enum
    DeltaTime,
    WindowTitle, WindowTitleCallback,
    WindowWidth, WindowHeight,
    MouseX, MouseY,
    FontSize, CurrentBufferId,
    VimMode, VimCommandText, VimCommandStart,
    VimCommandPosition, VimCommandCompletion,
    VimVisualRange, VimVisualBlockMode,
    VimSearchRanges, VimShowSearch,
    VimMessage,
    AsciiArt, DeleteBuffer,
    BufferId, Lines, Path,
    CursorLine, CursorColumn,
    ScrollX, ScrollY,
    ScrollTargetX, ScrollTargetY,
    ScrollSpeedX, ScrollSpeedY,
    MaxCharCount, LineCount,
    Tree, Parser,
    Text, CroppedText, MinimapText,
    ShowMinimap,
  RefStrings = ref seq[string]
  RangeTuples = seq[RangeTuple]
  WindowTitleCallbackType = proc (title: string)

schema Fact(Id, Attr):
  DeltaTime: float
  WindowTitle: string
  WindowTitleCallback: WindowTitleCallbackType
  WindowWidth: int
  WindowHeight: int
  MouseX: float
  MouseY: float
  FontSize: float
  CurrentBufferId: int
  VimMode: int
  VimCommandText: string
  VimCommandStart: char
  VimCommandPosition: int
  VimCommandCompletion: string
  VimVisualRange: RangeTuple
  VimVisualBlockMode: bool
  VimSearchRanges: RangeTuples
  VimShowSearch: bool
  VimMessage: string
  AsciiArt: string
  DeleteBuffer: int
  BufferId: int
  Lines: RefStrings
  Path: string
  CursorLine: int
  CursorColumn: int
  ScrollX: float
  ScrollY: float
  ScrollTargetX: float
  ScrollTargetY: float
  ScrollSpeedX: float
  ScrollSpeedY: float
  MaxCharCount: int
  LineCount: int
  Tree: pointer
  Parser: pointer
  Text: ParavimTextEntity
  CroppedText: ParavimTextEntity
  MinimapText: ParavimTextEntity
  ShowMinimap: bool

var
  session* = initSession(Fact)
  nextId* = Id.high.ord + 1
  baseMonoEntity: ptext.UncompiledTextEntity
  monoEntity*: ParavimTextEntity
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
    rule getMouse(Fact):
      what:
        (Global, MouseX, x)
        (Global, MouseY, y)
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
        (Global, VimMessage, message)
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
        (id, ScrollTargetX, scrollTargetX)
        (id, ScrollTargetY, scrollTargetY)
        (id, ScrollSpeedX, scrollSpeedX)
        (id, ScrollSpeedY, scrollSpeedY)
        (id, Text, text)
        (id, CroppedText, croppedText)
        (id, MinimapText, minimapText)
        (id, ShowMinimap, showMinimap)
        (id, VimVisualRange, visualRange)
        (id, VimVisualBlockMode, visualBlockMode)
        (id, VimSearchRanges, searchRanges)
    rule getBuffer(Fact):
      what:
        (id, BufferId, bufferId)
        (id, Lines, lines)
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX)
        (id, ScrollY, scrollY)
        (id, ScrollTargetX, scrollTargetX)
        (id, ScrollTargetY, scrollTargetY)
        (id, ScrollSpeedX, scrollSpeedX)
        (id, ScrollSpeedY, scrollSpeedY)
        (id, Text, text)
        (id, CroppedText, croppedText)
        (id, MinimapText, minimapText)
        (id, ShowMinimap, showMinimap)
        (id, VimVisualRange, visualRange)
        (id, VimVisualBlockMode, visualBlockMode)
        (id, VimSearchRanges, searchRanges)
        (id, Tree, tree)
        (id, Parser, parser)
    rule deleteBuffer(Fact):
      what:
        (Global, DeleteBuffer, bufferId)
        (id, BufferId, bufferId)
        (id, Lines, lines)
        (id, CursorLine, cursorLine)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX)
        (id, ScrollY, scrollY)
        (id, ScrollTargetX, scrollTargetX)
        (id, ScrollTargetY, scrollTargetY)
        (id, ScrollSpeedX, scrollSpeedX)
        (id, ScrollSpeedY, scrollSpeedY)
        (id, MaxCharCount, maxCharCount)
        (id, LineCount, lineCount)
        (id, Tree, tree)
        (id, Parser, parser)
        (id, Text, text)
        (id, CroppedText, croppedText)
        (id, MinimapText, minimapText)
        (id, ShowMinimap, showMinimap)
        (id, VimVisualRange, visualRange)
        (id, VimVisualBlockMode, visualBlockMode)
        (id, VimSearchRanges, searchRanges)
      then:
        session.retract(id, BufferId, bufferId)
        session.retract(id, Lines, lines)
        session.retract(id, CursorLine, cursorLine)
        session.retract(id, CursorColumn, cursorColumn)
        session.retract(id, ScrollX, scrollX)
        session.retract(id, ScrollY, scrollY)
        session.retract(id, ScrollTargetX, scrollTargetX)
        session.retract(id, ScrollTargetY, scrollTargetY)
        session.retract(id, ScrollSpeedX, scrollSpeedX)
        session.retract(id, ScrollSpeedY, scrollSpeedY)
        session.retract(id, MaxCharCount, maxCharCount)
        session.retract(id, LineCount, lineCount)
        session.retract(id, Tree, tree)
        tree_sitter.deleteTree(tree)
        session.retract(id, Parser, parser)
        tree_sitter.deleteParser(parser)
        session.retract(id, Text, text)
        session.retract(id, CroppedText, croppedText)
        session.retract(id, MinimapText, minimapText)
        session.retract(id, ShowMinimap, showMinimap)
        session.retract(id, VimVisualRange, visualRange)
        session.retract(id, VimVisualBlockMode, visualBlockMode)
        session.retract(id, VimSearchRanges, searchRanges)
    rule resizeWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
      then:
        let
          fontWidth = text.monoFontWidth * fontSize
          fontHeight = text.monoFont.height * fontSize
        libvim.vimWindowSetWidth(int32(windowWidth.float / fontWidth))
        libvim.vimWindowSetHeight(int32(windowHeight.float / fontHeight))
    rule updateCounts(Fact):
      what:
        (id, Lines, lines)
        (id, LineCount, lineCount, then = false)
      then:
        if lines[].len != lineCount:
          session.insert(id, LineCount, lines[].len)
        var maxCharCount = 0
        for line in lines[]:
          let count = line.len
          if count > maxCharcount:
            maxCharCount = count
        session.insert(id, MaxCharCount, maxCharCount)
    rule updateScrollTargetX(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, FontSize, fontSize)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX, then = false)
      then:
        let
          textWidth = text.monoFontWidth * fontSize
          cursorLeft = cursorColumn.float * textWidth
          cursorRight = cursorLeft + textWidth
          textViewWidth = windowWidth.float
          scrollRight = scrollX + textViewWidth
        if cursorLeft < scrollX:
          session.insert(id, ScrollTargetX, cursorLeft)
        elif cursorRight > scrollRight:
          session.insert(id, ScrollTargetX, cursorRight - textViewWidth)
    rule updateScrollTargetY(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
        (id, CursorLine, cursorLine)
        (id, ScrollY, scrollY, then = false)
        (id, LineCount, lineCount)
      then:
        let
          fontHeight = text.monoFont.height * fontSize
          cursorTop = cursorLine.float * fontHeight
          cursorBottom = cursorTop + fontHeight
          textViewHeight = windowHeight.float - fontHeight
          scrollBottom = scrollY + textViewHeight
          documentBottom = lineCount.float * fontHeight
        if cursorTop < scrollY:
          session.insert(id, ScrollTargetY, cursorTop)
        elif cursorBottom > scrollBottom and scrollBottom > 0:
          session.insert(id, ScrollTargetY, cursorBottom - textViewHeight)
    rule updateCroppedText(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
        (id, ScrollY, scrollY)
        (id, Text, fullText)
      then:
        var e = fullText
        let
          fontHeight = text.monoFont.height * fontSize
          linesToSkip = min(int(scrollY / fontHeight), e.lineCount).max(0)
          linesToCrop = min(linesToSkip + int(windowHeight.float / fontHeight) + 1, e.lineCount)
        text.cropLines(e, linesToSkip, linesToCrop)
        e.uniforms.u_start_line.data = linesToSkip.int32
        e.uniforms.u_start_line.disable = false
        e.uniforms.u_show_blocks.data = 0
        e.uniforms.u_show_blocks.disable = false
        session.insert(id, CroppedText, e)
    rule updateMinimapText(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
        (id, ScrollY, scrollY)
        (id, Text, fullText)
      then:
        var e = fullText
        const
          miniScale = 6f
          minSizeToShowChars = (defaultFontSize * 2) / miniScale
          minChars = 30f # minimum number of chars that minimap must be able to display
        let
          minimapFontSize = fontSize / miniScale
          minimapWidth = float(windowWidth)/miniScale
          minimapChars = minimapWidth/(minimapFontSize * text.monoFontWidth) # number of chars that can fit in minimap
        if minimapFontSize >= minSizeToShowChars:
          e.uniforms.u_show_blocks.data = 0
          e.uniforms.u_show_blocks.disable = false
        e.project(float(windowWidth), float(windowHeight))
        e.translate(float(windowWidth) - minimapWidth, 0f)
        e.scale(minimapFontSize, minimapFontSize)
        session.insert(id, MinimapText, e)
        let
          fontHeight = text.monoFont.height * fontSize
          textViewHeight = windowHeight.float - fontHeight
          documentHeight = fullText.lineCount.float * fontHeight
        session.insert(id, ShowMinimap, minimapChars >= minChars and documentHeight > textViewHeight)
    rule rubberBandEffectX(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, FontSize, fontSize)
        (id, ScrollTargetX, scrollTargetX)
        (id, MaxCharCount, maxCharCount)
      then:
        let
          fontWidth = text.monoFontWidth * fontSize
          textWidth = fontWidth * maxCharCount.float
          maxX = textWidth - windowWidth.float
          newScrollTargetX = scrollTargetX.min(maxX).max(0)
        if newScrollTargetX != scrollTargetX:
          session.insert(id, ScrollTargetX, newScrollTargetX)
          session.insert(id, ScrollSpeedX, scroll.minScrollSpeed)
    rule rubberBandEffectY(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Global, FontSize, fontSize)
        (id, ScrollTargetY, scrollTargetY)
        (id, LineCount, lineCount)
      then:
        let
          fontHeight = text.monoFont.height * fontSize
          textHeight = fontHeight * lineCount.float
          maxY = textHeight - (windowHeight.float - fontHeight)
          newScrollTargetY = scrollTargetY.min(maxY).max(0)
        if newScrollTargetY != scrollTargetY:
          session.insert(id, ScrollTargetY, newScrollTargetY)
          session.insert(id, ScrollSpeedY, scroll.minScrollSpeed)
    rule moveCameraToTarget(Fact):
      what:
        (Global, DeltaTime, deltaTime)
        (id, ScrollX, scrollX, then = false)
        (id, ScrollY, scrollY, then = false)
        (id, ScrollTargetX, scrollTargetX, then = false)
        (id, ScrollTargetY, scrollTargetY, then = false)
        (id, ScrollSpeedX, scrollSpeedX, then = false)
        (id, ScrollSpeedY, scrollSpeedY, then = false)
      cond:
        scrollX != scrollTargetX or scrollY != scrollTargetY
      then:
        let
          scrollData = (
            scrollX, scrollY,
            scrollTargetX, scrollTargetY,
            scrollSpeedX, scrollSpeedY
          )
          ret = scroll.animateCamera(scrollData, deltaTime)
        session.insert(id, ScrollX, ret.x)
        session.insert(id, ScrollY, ret.y)
        session.insert(id, ScrollSpeedX, ret.speedX)
        session.insert(id, ScrollSpeedY, ret.speedY)

proc getCurrentSessionId*(): int =
  let index = session.find(rules.getCurrentBuffer)
  if index >= 0:
    session.get(rules.getCurrentBuffer, index).id
  else:
    -1

for r in rules.fields:
  session.add(r)

func mouseToCursorPosition(
      mouseX: float, mouseY: float, scrollX: float, scrollY: float, fontWidth: float, fontHeight: float
    ): tuple[line: int, column: int] =
  let
    column = (mouseX + scrollX) / fontWidth
    line = (mouseY + scrollY) / fontHeight
  (column.int, line.int)

proc onMouseClick*(button: int) =
  if button == 0: # left
    let
      mouse = session.query(rules.getMouse)
      index = session.find(rules.getCurrentBuffer)
    if index >= 0:
      let
        buffer = session.get(rules.getCurrentBuffer, index)
        (fontSize) = session.query(rules.getFont)
        fontWidth = text.monoFontWidth * fontSize
        fontHeight = text.monoFont.height * fontSize
        (column, line) = mouseToCursorPosition(mouse.x, mouse.y, buffer.scrollX, buffer.scrollY, fontWidth, fontHeight)
      var pos: structs.pos_T
      pos.lnum = line.int32 + 1 # lines in libvim are 1-based
      pos.col = column.int32
      libvim.vimCursorSetPosition(pos)
      session.insert(buffer.id, CursorLine, line)
      session.insert(buffer.id, CursorColumn, column)

proc onMouseMove*(xpos: float, ypos: float) =
  session.insert(Global, MouseX, xpos)
  session.insert(Global, MouseY, ypos)

proc onWindowResize*(width: int, height: int) =
  if width == 0 or height == 0:
    return
  session.insert(Global, WindowWidth, width)
  session.insert(Global, WindowHeight, height)

proc onScroll*(xoffset: float64, yoffset: float64) =
  let index = session.find(rules.getCurrentBuffer)
  if index == -1:
    return
  let
    buffer = session.get(rules.getCurrentBuffer, index)
    scrollData = (
      buffer.scrollX, buffer.scrollY,
      buffer.scrollTargetX, buffer.scrollTargetY,
      buffer.scrollSpeedX, buffer.scrollSpeedY
    )
    ret = scroll.startScrollingCamera(scrollData, xoffset, yoffset)
  session.insert(buffer.id, ScrollSpeedX, ret.speedX)
  session.insert(buffer.id, ScrollSpeedY, ret.speedY)
  session.insert(buffer.id, ScrollTargetX, ret.targetX)
  session.insert(buffer.id, ScrollTargetY, ret.targetY)

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

proc insertTextEntity*(id: int, lines: RefStrings, parsed: tree_sitter.Nodes) =
  var e = deepCopy(monoEntity)
  for i in 0 ..< lines[].len:
    let parsedLine = if parsed != nil: parsed[i] else: @[]
    discard text.addLine(e, baseMonoEntity, text.monoFont, textColor, lines[][i], parsedLine)
  e.parsedNodes = parsed
  e.lineCount = lines[].len
  e.uniforms.u_start_line.data = 0
  e.uniforms.u_start_line.disable = false
  e.uniforms.u_show_blocks.data = 1
  e.uniforms.u_show_blocks.disable = false
  session.insert(id, Text, e)

proc parsedNodesChanged(parsedNodes: tree_sitter.Nodes, textEntity: ParavimTextEntity, startLine: int, oldEndLine: int, newEndLine: int): bool =
  if parsedNodes == nil or textEntity.parsedNodes == nil:
    return false
  let
    newPrevLines = parsedNodes[][0..<startLine]
    oldPrevLines = textEntity.parsedNodes[][0..<startLine]
  if newPrevLines != oldPrevLines:
    return true
  let
    newLength = parsedNodes[].len
    oldLength = textEntity.parsedNodes[].len
    newNextLines = parsedNodes[][newEndLine..<newLength]
    oldNextLines = textEntity.parsedNodes[][oldEndLine..<oldLength]
  if newNextLines != oldNextLines:
    return true
  false

proc updateTextEntity*(id: int, lines: RefStrings, parsed: tree_sitter.Nodes, textEntity: ParavimTextEntity, bu: BufferUpdateTuple) =
  var
    e = textEntity
    nextEntity = textEntity
    startLine = bu.firstLine
    oldEndLine = startLine + bu.lines.len
    newEndLine = oldEndLine
  text.cropLines(e, 0, startLine)
  if bu.lineCountChange == 0:
    text.cropLines(nextEntity, oldEndLine, lines[].len)
  else:
    let linesToRemove =
      if bu.lineCountChange < 0:
        (-1 * bu.lineCountChange) + bu.lines.len
      else:
        bu.lines.len - bu.lineCountChange
    oldEndLine = startLine + linesToRemove
    text.cropLines(nextEntity, oldEndLine)
  for i in 0 ..< bu.lines.len:
    let
      lineNum = bu.firstLine + i
      parsedLine = if parsed != nil: parsed[lineNum] else: @[]
    discard text.addLine(e, baseMonoEntity, text.monoFont, textColor, bu.lines[i], parsedLine)
  text.add(e, nextEntity)
  if parsedNodesChanged(parsed, e, startLine, oldEndLine, newEndLine):
    text.updateColors(e, parsed, lines, textColor)
  e.parsedNodes = parsed
  e.lineCount = lines[].len
  # u_char_counts must not be empty
  # because there is always at least one line
  if e.uniforms.u_char_counts.data.len == 0:
    e.uniforms.u_char_counts.data = @[0.int32]
    e.uniforms.u_char_counts.disable = false
  e.uniforms.u_start_line.data = 0
  e.uniforms.u_start_line.disable = false
  e.uniforms.u_show_blocks.data = 1
  e.uniforms.u_show_blocks.disable = false
  session.insert(id, Text, e)

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
  session.insert(Global, FontSize, defaultFontSize * density)
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
  session.insert(Global, MouseX, 0f)
  session.insert(Global, MouseY, 0f)

proc tick*(game: RootGame, clear: bool): bool =
  result = false # if true, the game loop must continue immediately because we're animating

  let
    (windowWidth, windowHeight, ascii) = session.query(rules.getWindow)
    (fontSize) = session.query(rules.getFont)
    vim = session.query(rules.getVim)
    currentBufferIndex = session.find(rules.getCurrentBuffer)
    fontWidth = text.monoFontWidth * fontSize
    fontHeight = text.monoFont.height * fontSize

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
    e.uniforms.u_show_blocks.data = 0
    e.uniforms.u_show_blocks.disable = false
    for line in asciiArt[ascii]:
      discard text.addLine(e, baseMonoEntity, text.monoFont, asciiColor, line, [])
    e.project(float(windowWidth), float(windowHeight))
    e.scale(fontSize, fontSize)
    render(game, e)
  elif currentBufferIndex >= 0:
    let currentBuffer = session.get(rules.getCurrentBuffer, currentBufferIndex)
    result =
      currentBuffer.scrollX != currentBuffer.scrollTargetX or
      currentBuffer.scrollY != currentBuffer.scrollTargetY
    var camera = glm.mat3f(1)
    camera.translate(currentBuffer.scrollX, currentBuffer.scrollY)
    block:
      var e = deepCopy(rectsEntity)
      # cursor
      if vim.mode != libvim.CommandLine.ord:
        var e2 = uncompiledRectEntity
        e2.project(float(windowWidth), float(windowHeight))
        e2.invert(camera)
        e2.translate(currentBuffer.cursorColumn.GLfloat * fontWidth, currentBuffer.cursorLine.GLfloat * fontHeight)
        e2.scale(if vim.mode == libvim.Insert.ord: fontWidth / 4 else: fontWidth, fontHeight)
        e2.color(cursorColor)
        e.add(e2)
      # selection
      if currentBuffer.visualRange != (0, 0, 0, 0):
        let
          rects =
            if currentBuffer.visualBlockMode:
              @[buffers.rangeToRect(buffers.normalizeRange(currentBuffer.visualRange, true))]
            else:
              buffers.rangeToRects(buffers.normalizeRange(currentBuffer.visualRange, false), currentBuffer.lines)
        for (left, top, width, height) in rects:
          var e2 = uncompiledRectEntity
          e2.project(float(windowWidth), float(windowHeight))
          e2.invert(camera)
          e2.scale(fontWidth, fontHeight)
          e2.translate(left, top)
          e2.scale(width, height)
          e2.color(selectColor)
          e.add(e2)
      # search
      if vim.showSearch:
        for highlight in currentBuffer.searchRanges:
          let rects = buffers.rangeToRects(highlight, currentBuffer.lines)
          for (left, top, width, height) in rects:
            var e2 = uncompiledRectEntity
            e2.project(float(windowWidth), float(windowHeight))
            e2.invert(camera)
            e2.scale(fontWidth, fontHeight)
            e2.translate(left, top)
            e2.scale(width, height)
            e2.color(searchColor)
            e.add(e2)
      if e.instanceCount > 0:
        render(game, e)
    # text
    block:
      var e = currentBuffer.croppedText
      if e.instanceCount > 0:
        e.project(float(windowWidth), float(windowHeight))
        e.invert(camera)
        e.scale(fontSize, fontSize)
        render(game, e)
    # mini map
    block:
      if currentBuffer.showMinimap and currentBuffer.minimapText.instanceCount > 0:
        var e = currentBuffer.minimapText
        render(game, e)

  # command line background
  block:
    var e = rectEntity
    e.project(float(windowWidth), float(windowHeight))
    e.translate(0f, float(windowHeight) - fontHeight)
    e.scale(float(windowWidth), fontHeight)
    e.color(
      if vim.mode == libvim.CommandLine.ord:
        tanColor
      elif vim.message != "":
        redColor
      else:
        bgColor
    )
    render(game, e)
  if vim.mode == libvim.CommandLine.ord:
    # command line cursor
    block:
      var e = rectEntity
      e.project(float(windowWidth), float(windowHeight))
      e.translate((vim.commandPosition.float + 1) * fontWidth, float(windowHeight) - fontHeight)
      e.scale(fontWidth / 4, fontHeight)
      e.color(cursorColor)
      render(game, e)
    # command line text
    block:
      var e = deepCopy(monoEntity)
      e.uniforms.u_start_line.data = 0
      e.uniforms.u_start_line.disable = false
      e.uniforms.u_show_blocks.data = 0
      e.uniforms.u_show_blocks.disable = false
      let endPos = text.addLine(e, baseMonoEntity, text.monoFont, bgColor, vim.commandStart & vim.commandText, [])
      if vim.commandCompletion != "":
        let
          compLen = vim.commandCompletion.len
          commLen = vim.commandText.len
        if compLen > commLen:
          discard text.add(e, baseMonoEntity, text.monoFont, completionColor, vim.commandCompletion[commLen ..< compLen], [], endPos)
      e.project(float(windowWidth), float(windowHeight))
      e.translate(0f, float(windowHeight) - fontHeight)
      e.scale(fontSize, fontSize)
      render(game, e)
  elif vim.message != "":
    var e = deepCopy(monoEntity)
    e.uniforms.u_start_line.data = 0
    e.uniforms.u_start_line.disable = false
    e.uniforms.u_show_blocks.data = 0
    e.uniforms.u_show_blocks.disable = false
    discard text.addLine(e, baseMonoEntity, text.monoFont, textColor, vim.message, [])
    e.project(float(windowWidth), float(windowHeight))
    e.translate(0f, float(windowHeight) - fontHeight)
    e.scale(fontSize, fontSize)
    render(game, e)
