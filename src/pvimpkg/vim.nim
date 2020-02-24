import libvim, structs, core
from os import nil

proc onBufEnter(buf: buf_T) =
  let
    id = vimBufferGetId(buf)
    path = vimBufferGetFilename(buf)
    count = vimBufferGetLineCount(buf)
  session.insert(Global, CurrentBufferId, id)
  if path != nil:
    var lines: seq[cstring]
    for i in 0 ..< count:
      let line = vimBufferGetLine(buf, linenr_T(i+1))
      lines.add(cstring(line))
    session.insert(nextId, BufferId, id)
    session.insert(nextId, Path, cstring(path))
    session.insert(nextId, Lines, lines)
    nextId += 1

proc onAutoCommand(a1: event_T; buf: buf_T) {.cdecl.} =
  case a1:
    of EVENT_BUFENTER:
      onBufEnter(buf)
    else:
      discard

proc onBufferUpdate(bufferUpdate: bufferUpdate_T) {.cdecl.} =
  echo bufferUpdate

proc init*() =
  vimSetAutoCommandCallback(onAutoCommand)
  vimSetBufferUpdateCallback(onBufferUpdate)
  vimInit(0, nil)

  #let params = os.commandLineParams()
  #for fname in params:
  #  discard vimBufferOpen(fname, 1, 0)
  discard vimBufferOpen("tests/hello.txt", 1, 0)
