import libvim, structs, core
from os import nil
from strutils import nil

const validCommandStarts = {':', '?', '/'}

proc onInput*(input: string) =
  let oldMode = vimGetMode()
  vimInput(input)
  let mode = vimGetMode()
  session.insert(Global, VimMode, mode)
  let id = getCurrentSessionId()
  if id >= 0:
    session.insert(id, CursorLine, vimCursorGetLine() - 1)
    session.insert(id, CursorColumn, vimCursorGetColumn())
  if mode == libvim.CommandLine.ord:
    session.insert(Global, VimCommandText, $ vimCommandLineGetText())
    if oldMode != mode:
      session.insert(Global, VimCommandStart, if not validCommandStarts.contains(input[0]): ":" else: input)

proc onBufEnter(buf: buf_T) =
  let
    bufferId = vimBufferGetId(buf)
    path = vimBufferGetFilename(buf)
    count = vimBufferGetLineCount(buf)
  session.insert(Global, CurrentBufferId, bufferId)
  var sessionId = getSessionId(bufferId)
  if path != nil:
    if sessionId == -1:
      sessionId = nextId
      nextId += 1
      var lines: seq[string]
      for i in 0 ..< count:
        let line = vimBufferGetLine(buf, linenr_T(i+1))
        lines.add($ line)
      session.insert(sessionId, BufferId, bufferId)
      session.insert(sessionId, Path, $ path)
      session.insert(sessionId, Lines, lines)
      session.insert(sessionId, CursorLine, vimCursorGetLine() - 1)
      session.insert(sessionId, CursorColumn, vimCursorGetColumn())
      session.insert(sessionId, ScrollX, 0f)
      session.insert(sessionId, ScrollY, 0f)
      session.insert(sessionId, LineCount, count)

proc onBufDelete(buf: buf_T) =
  discard

proc onAutoCommand(a1: event_T; buf: buf_T) {.cdecl.} =
  case a1:
    of EVENT_BUFENTER:
      onBufEnter(buf)
    of EVENT_BUFDELETE:
      onBufDelete(buf)
    else:
      discard

proc onBufferUpdate(bufferUpdate: bufferUpdate_T) {.cdecl.} =
  let
    firstLine = bufferUpdate.lnum - 1
    lastLine = bufferUpdate.lnume - 1 + bufferUpdate.xtra
  var lines: seq[string]
  for i in firstLine ..< lastLine:
    let line = vimBufferGetLine(bufferUpdate.buf, linenr_T(i+1))
    lines.add($ line)
  let id = vimBufferGetId(bufferUpdate.buf)
  session.insert(Global, BufferUpdate, (id.int, lines, firstLine.int, bufferUpdate.xtra.int))

proc init*(quitCallback: QuitCallback) =
  vimSetAutoCommandCallback(onAutoCommand)
  vimSetBufferUpdateCallback(onBufferUpdate)
  vimSetQuitCallback(quitCallback)
  vimInit(0, nil)
  vimExecute("set hidden")
  vimExecute("set noswapfile")
  vimExecute("set nobackup")
  vimExecute("set nowritebackup")
  vimExecute("set tabstop=2")
  vimExecute("set softtabstop=2")
  vimExecute("set shiftwidth=2")
  vimExecute("set expandtab")
  vimExecute("set hlsearch")
  vimExecute("filetype plugin index on")

  session.insert(Global, VimMode, vimGetMode())
  session.insert(Global, VimCommandText, "")
  session.insert(Global, VimCommandStart, "")

  #let params = os.commandLineParams()
  #for fname in params:
  #  discard vimBufferOpen(fname, 1, 0)
  discard vimBufferOpen("src/pvim.nim", 1, 0)
