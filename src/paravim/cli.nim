from illwill as iw import nil
import strutils

proc exitProc() {.noconv.} =
  iw.illwillDeinit()
  iw.showCursor()
  quit(0)

proc init*() =
  iw.illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  iw.hideCursor()

proc tick*() =
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
  of iw.Key.Escape, iw.Key.Q: exitProc()
  else:
    iw.write(tb, 8, 4, ' '.repeat(31))
    iw.write(tb, 2, 4, iw.resetStyle, "Key pressed: ", iw.fgGreen, $key)
  iw.setCursorPos(tb, 0, 0)
  iw.display(tb)
