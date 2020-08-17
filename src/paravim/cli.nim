from illwill as iw import nil
import strutils

var tb: iw.TerminalBuffer

proc exitProc() {.noconv.} =
  iw.illwillDeinit()
  iw.showCursor()
  quit(0)

proc init*() =

  iw.illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  iw.hideCursor()

  tb = iw.newTerminalBuffer(iw.terminalWidth(), iw.terminalHeight())

  iw.setForegroundColor(tb, iw.fgBlack, true)
  iw.drawRect(tb, 0, 0, 40, 5)
  iw.drawHorizLine(tb, 2, 38, 3, doubleStyle=true)

  iw.write(tb, 2, 1, iw.fgWhite, "Press any key to display its name")
  iw.write(tb, 2, 2, "Press ", iw.fgYellow, "ESC", iw.fgWhite,
           " or ", iw.fgYellow, "Q", iw.fgWhite, " to quit")

proc tick*() =
  var key = iw.getKey()
  case key
  of iw.Key.None: discard
  of iw.Key.Escape, iw.Key.Q: exitProc()
  else:
    iw.write(tb, 8, 4, ' '.repeat(31))
    iw.write(tb, 2, 4, iw.resetStyle, "Key pressed: ", iw.fgGreen, $key)
  iw.display(tb)
