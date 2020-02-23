import libvim, structs
from os import nil

proc onAutoCommand(a1: event_T; buf: buf_T) {.cdecl.} =
  echo a1
  case a1:
    of EVENT_BUFENTER:
      discard
    else:
      discard

proc onBufferUpdate(bufferUpdate: bufferUpdate_T) {.cdecl.} =
  echo bufferUpdate

proc init*() =
  vimSetAutoCommandCallback(onAutoCommand)
  vimSetBufferUpdateCallback(onBufferUpdate)
  vimInit(0, nil)

  let params = os.commandLineParams()
  for fname in params:
    discard vimBufferOpen(fname, 1, 0)
