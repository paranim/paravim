import libvim, structs, core
from os import nil

proc onInput*(input: string) =
  vimInput(input)
  let id = getCurrentBufferId()
  if id >= 0:
    session.insert(id, CursorLine, vimCursorGetLine() - 1)
    session.insert(id, CursorColumn, vimCursorGetColumn())

proc onBufEnter(buf: buf_T) =
  let
    id = vimBufferGetId(buf)
    path = vimBufferGetFilename(buf)
    count = vimBufferGetLineCount(buf)
  session.insert(Global, CurrentBufferId, id)
  if path != nil:
    var lines: seq[string]
    for i in 0 ..< count:
      let line = vimBufferGetLine(buf, linenr_T(i+1))
      lines.add($ line)
    session.insert(nextId, BufferId, id)
    session.insert(nextId, Path, $ path)
    session.insert(nextId, Lines, lines)
    session.insert(nextId, CursorLine, vimCursorGetLine() - 1)
    session.insert(nextId, CursorColumn, vimCursorGetColumn())
    nextId += 1

proc onAutoCommand(a1: event_T; buf: buf_T) {.cdecl.} =
  case a1:
    of EVENT_BUFENTER:
      onBufEnter(buf)
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

  #let params = os.commandLineParams()
  #for fname in params:
  #  discard vimBufferOpen(fname, 1, 0)
  discard vimBufferOpen("tests/hello.txt", 1, 0)
