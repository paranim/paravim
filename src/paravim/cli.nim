from illwill as iw import nil
from pararules import nil
from paravim/vim import nil
from paravim/structs import nil
from paravim/core import nil
import strutils
import tables

const iwToVimSpecials =
  {iw.Key.Backspace.ord: "BS",
   iw.Key.Delete.ord: "Del",
   iw.Key.Tab.ord: "Tab",
   iw.Key.Enter.ord: "Enter",
   iw.Key.Escape.ord: "Esc",
   iw.Key.Up.ord: "Up",
   iw.Key.Down.ord: "Down",
   iw.Key.Left.ord: "Left",
   iw.Key.Right.ord: "Right",
   iw.Key.Home.ord: "Home",
   iw.Key.End.ord: "End",
   iw.Key.PageUp.ord: "PageUp",
   iw.Key.PageDown.ord: "PageDown"}.toTable

proc exitProc() {.noconv.} =
  iw.illwillDeinit()
  iw.showCursor()
  quit(0)

proc init*() =
  iw.illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  iw.hideCursor()

  proc onQuit(buf: pointer; isForced: cint) {.cdecl.} =
    exitProc()

  proc onYank(yankInfo: ptr structs.yankInfo_T) {.cdecl.} =
    discard

  core.onWindowResize(iw.terminalWidth(), iw.terminalHeight())
  vim.init(onQuit, onYank)
  core.initAscii(true)

proc tick*() =
  pararules.fireRules(core.session)
  let
    (windowWidth, windowHeight, ascii) = pararules.query(core.session, core.rules.getWindow)
    vimInfo = pararules.query(core.session, core.rules.getVim)
    currentBufferIndex = pararules.find(core.session, core.rules.getCurrentBuffer)

  var tb = iw.newTerminalBuffer(iw.terminalWidth(), iw.terminalHeight())

  iw.setForegroundColor(tb, iw.fgBlack, true)
  iw.drawRect(tb, 0, 0, iw.width(tb)-1, iw.height(tb)-1)
  iw.drawHorizLine(tb, 2, 38, 3, doubleStyle=true)

  iw.write(tb, 2, 1, iw.fgWhite, "Press any key to display its name")
  iw.write(tb, 2, 2, "Press ", iw.fgYellow, "ESC", iw.fgWhite,
           " or ", iw.fgYellow, "Q", iw.fgWhite, " to quit")

  var key = iw.getKey()
  case key
  of iw.Key.None: discard
  else:
    let code = key.ord
    if iwToVimSpecials.hasKey(code):
      vim.onInput("<" & iwToVimSpecials[code] & ">")
    elif code > 32:
      vim.onInput($ char(code))
      #iw.write(tb, 2, 3, $code)
  iw.setCursorPos(tb, 0, 0)
  iw.display(tb)
