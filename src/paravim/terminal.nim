import illwill as iw
import pararules
from paravim/libvim import nil
from paravim/vim import nil
from paravim/structs import nil
import paravim/core
from paravim/buffers import nil
import strutils
import tables

let termRules =
  ruleset:
    rule getTerminalWindow(Fact):
      what:
        (Global, WindowColumns, windowColumns)
        (Global, WindowLines, windowLines)
        (Global, AsciiArt, ascii)
    rule resizeTerminalWindow(Fact):
      what:
        (Global, WindowColumns, windowColumns)
        (Global, WindowLines, windowLines)
      then:
        libvim.vimWindowSetWidth(windowColumns.int32)
        libvim.vimWindowSetHeight(windowLines.int32)
    rule updateTerminalScrollX(Fact):
      what:
        (Global, WindowColumns, windowColumns)
        (id, CursorColumn, cursorColumn)
        (id, ScrollX, scrollX, then = false)
      then:
        let scrollRight = scrollX.int + windowColumns - 1
        if cursorColumn < scrollX.int:
          session.insert(id, ScrollX, cursorColumn.float)
        elif cursorColumn > scrollRight:
          session.insert(id, ScrollX, scrollX + float(cursorColumn - scrollRight))
    rule updateTerminalScrollY(Fact):
      what:
        (Global, WindowLines, windowLines)
        (id, CursorLine, cursorLine)
        (id, ScrollY, scrollY, then = false)
      then:
        let scrollBottom = scrollY.int + windowLines - 2
        if cursorLine < scrollY.int:
          session.insert(id, ScrollY, cursorLine.float)
        elif cursorLine > scrollBottom:
          session.insert(id, ScrollY, scrollY + float(cursorLine - scrollBottom))

const iwToVimSpecials =
  {iw.Key.Backspace.ord: "<BS>",
   iw.Key.Delete.ord: "<Del>",
   iw.Key.Tab.ord: "<Tab>",
   iw.Key.Enter.ord: "<Enter>",
   iw.Key.Escape.ord: "<Esc>",
   iw.Key.Up.ord: "<Up>",
   iw.Key.Down.ord: "<Down>",
   iw.Key.Left.ord: "<Left>",
   iw.Key.Right.ord: "<Right>",
   iw.Key.Home.ord: "<Home>",
   iw.Key.End.ord: "<End>",
   iw.Key.PageUp.ord: "<PageUp>",
   iw.Key.PageDown.ord: "<PageDown>",
   iw.Key.CtrlD.ord: "<C-D>",
   iw.Key.CtrlR.ord: "<C-R>",
   iw.Key.CtrlU.ord: "<C-U>",
   iw.Key.CtrlV.ord: "<C-V>",}.toTable

proc onWindowResize(width: int, height: int) =
  core.insert(core.session, core.Global, core.WindowColumns, width)
  core.insert(core.session, core.Global, core.WindowLines, height)

proc exitProc() {.noconv.} =
  iw.illwillDeinit()
  iw.showCursor()
  quit(0)

proc init*(params: seq[string]) =
  iw.illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  iw.hideCursor()

  proc onQuit(buf: pointer; isForced: cint) {.cdecl.} =
    exitProc()

  proc onYank(yankInfo: ptr structs.yankInfo_T) {.cdecl.} =
    discard

  for r in termRules.fields:
    session.add(r)

  onWindowResize(iw.terminalWidth(), iw.terminalHeight())
  vim.init(onQuit, onYank)
  core.initAscii(params.len == 0)

  for fname in params:
    discard libvim.vimBufferOpen(fname, 1, 0)

proc setCharBackground(tb: var iw.TerminalBuffer, col: int, row: int, color: iw.BackgroundColor, cursor: bool) =
  if col < 0 or row < 0:
    return
  var ch = tb[col, row]
  ch.bg = color
  tb[col, row] = ch
  if cursor:
    iw.setCursorPos(tb, col, row)

proc tick*() =
  var key = iw.getKey()
  case key
  of iw.Key.None: discard
  else:
    let code = key.ord
    if iwToVimSpecials.hasKey(code):
      vim.onInput(iwToVimSpecials[code])
    elif code >= 32:
      vim.onInput($ char(code))
  pararules.fireRules(core.session)

  let
    (windowColumns, windowLines, ascii) = pararules.query(core.session, termRules.getTerminalWindow)
    vimInfo = pararules.query(core.session, core.rules.getVim)
    currentBufferIndex = pararules.find(core.session, core.rules.getCurrentBuffer)

  let
    width = iw.terminalWidth()
    height = iw.terminalHeight()
  var tb = iw.newTerminalBuffer(width, height)
  if width != windowColumns or height != windowLines:
    onWindowResize(width, height)

  if ascii != "":
    let lines = core.asciiArt[ascii]
    for i in 0 ..< lines.len:
      iw.write(tb, 0, i, lines[i])
  elif currentBufferIndex >= 0:
    let currentBuffer = pararules.get(core.session, core.rules.getCurrentBuffer, currentBufferIndex)
    # text
    let
      lines = currentBuffer.lines[]
      scrollX = currentBuffer.scrollX.int
      scrollY = currentBuffer.scrollY.int
    var screenLine = 0
    for i in scrollY ..< lines.len:
      if screenLine >= height - 1:
        break
      var line = lines[i]
      if scrollX < line.len:
        if scrollX > 0:
          line = line[scrollX ..< line.len]
      else:
        line = ""
      iw.write(tb, 0, screenLine, line)
      screenLine += 1
    # selection
    if currentBuffer.visualRange != (0, 0, 0, 0):
      let
        rects =
          if currentBuffer.visualBlockMode:
            @[buffers.rangeToRect(buffers.normalizeRange(currentBuffer.visualRange, true))]
          else:
            buffers.rangeToRects(buffers.normalizeRange(currentBuffer.visualRange, false), currentBuffer.lines)
      for (left, top, width, height) in rects:
        for col in left.int ..< int(left + width):
          for row in top.int ..< int(top + height):
            setCharBackground(tb, col - currentBuffer.scrollX.int, row - currentBuffer.scrollY.int, iw.bgCyan, false)
    # search
    if vimInfo.showSearch:
      for highlight in currentBuffer.searchRanges:
        let rects = buffers.rangeToRects(highlight, currentBuffer.lines)
        for (left, top, width, height) in rects:
          for col in left.int ..< int(left + width):
            for row in top.int ..< int(top + height):
              setCharBackground(tb, col - currentBuffer.scrollX.int, row - currentBuffer.scrollY.int, iw.bgMagenta, false)
    # cursor
    if vimInfo.mode != libvim.CommandLine.ord:
      let
        col = currentBuffer.cursorColumn - currentBuffer.scrollX.int
        row = currentBuffer.cursorLine - currentBuffer.scrollY.int
      setCharBackground(tb, col, row, iw.bgYellow, true)

  let cmdLineNum = height-1
  if vimInfo.mode == libvim.CommandLine.ord:
    # command line text
    iw.write(tb, 0, cmdLineNum, vimInfo.commandStart & vimInfo.commandText)
    if vimInfo.commandCompletion != "":
      let
        compLen = vimInfo.commandCompletion.len
        commLen = vimInfo.commandText.len
      if compLen > commLen:
        iw.write(tb, commLen+1, cmdLineNum, iw.fgBlue, vimInfo.commandCompletion[commLen ..< compLen])
    # command line cursor
    let col = vimInfo.commandPosition + 1
    setCharBackground(tb, col, cmdLineNum, iw.bgYellow, true)
  elif vimInfo.message != "":
    iw.write(tb, 0, cmdLineNum, iw.bgRed, vimInfo.message)

  iw.display(tb)
