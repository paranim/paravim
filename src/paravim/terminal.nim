import illwill as iw
from pararules import nil
from paravim/libvim import nil
from paravim/vim import nil
from paravim/structs import nil
from paravim/core import nil
from paravim/buffers import nil
import strutils
import tables

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
   iw.Key.CtrlH.ord: "<C-H>",
   iw.Key.CtrlJ.ord: "<C-J>",
   iw.Key.CtrlP.ord: "<C-P>",
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

  onWindowResize(iw.terminalWidth(), iw.terminalHeight())
  vim.init(onQuit, onYank)
  core.initAscii(true)

  for fname in params:
    discard libvim.vimBufferOpen(fname, 1, 0)

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
    (windowColumns, windowLines, ascii) = pararules.query(core.session, core.rules.getTerminalWindow)
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
      if scrollX > 0 and scrollX < line.len:
        line = line[scrollX ..< line.len]
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
            var ch = tb[col, row]
            ch.bg = iw.bgMagenta
            tb[col, row] = ch
    # cursor
    let
      cursorColumn = currentBuffer.cursorColumn - currentBuffer.scrollX.int
      cursorLine = currentBuffer.cursorLine - currentBuffer.scrollY.int
    var ch = tb[cursorColumn, cursorLine]
    ch.bg = iw.bgYellow
    tb[cursorColumn, cursorLine] = ch

  if vimInfo.mode == libvim.CommandLine.ord:
    iw.write(tb, 0, height-1, vimInfo.commandStart & vimInfo.commandText)
    if vimInfo.commandCompletion != "":
      let
        compLen = vimInfo.commandCompletion.len
        commLen = vimInfo.commandText.len
      if compLen > commLen:
        iw.write(tb, commLen+1, height-1, iw.fgYellow, vimInfo.commandCompletion[commLen ..< compLen])

  iw.setCursorPos(tb, 0, 0)
  iw.display(tb)