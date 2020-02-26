import libvim, structs, core
from pararules import nil
from os import nil
from strutils import nil
import tables

proc cropCommandText(commandText: string): string =
  result = ""
  let index = strutils.rfind(commandText, ' ')
  if index >= 0:
    result = ":" & commandText[0 ..< index]

proc completeCommand() =
  let vim = pararules.query(session, rules.getVim)
  if vim.commandText.len == vim.commandPosition:
    let firstPart = cropCommandText(vim.commandText)
    # delete everything after the first part of the command
    for _ in firstPart.len ..< vim.commandText.len:
      vimInput("<BS>")
    # input everything from the completion
    for i in firstPart.len ..< vim.commandCompletion.len:
      vimInput($ vim.commandCompletion[i])

const validCommandStarts = {':', '?', '/'}

proc executeCommand() =
  let vim = pararules.query(session, rules.getVim)
  if asciiArt.hasKey(vim.commandText):
    session.insert(Global, AsciiArt, vim.commandText)
    vimInput("<Esc>")
  else:
    vimInput("<Enter>")

proc updateCommand(input: string, start: bool) =
  let
    commandText = $ vimCommandLineGetText()
    commandPos = vimCommandLineGetPosition()
  session.insert(Global, VimCommandText, commandText)
  session.insert(Global, VimCommandPosition, commandPos)
  if start:
    session.insert(Global, VimCommandStart, if not validCommandStarts.contains(input[0]): ":" else: input)
  var completion = ""
  let strippedText = strutils.strip(commandText)
  if strippedText.len > 0 and
     not strutils.startsWith(strippedText, "!") and # don't try to complete shell commands
     commandText.len == commandPos:
    var
      completions: cstringArray
      count: cint
    vimCommandLineGetCompletions(completions.addr, count.addr)
    if count > 0:
      let
        firstPart = cropCommandText(commandText)
      completion = firstPart & $ completions[0]
  session.insert(Global, VimCommandCompletion, completion)

proc onInput*(input: string) =
  let oldMode = vimGetMode()
  if oldMode == libvim.CommandLine.ord and input == "<Tab>":
    completeCommand()
  elif oldMode == libvim.CommandLine.ord and input == "<Enter>":
    executeCommand()
  else:
    session.insert(Global, AsciiArt, "")
    vimInput(input)
  let mode = vimGetMode()
  session.insert(Global, VimMode, mode)
  let id = getCurrentSessionId()
  if id >= 0:
    session.insert(id, CursorLine, vimCursorGetLine() - 1)
    session.insert(id, CursorColumn, vimCursorGetColumn())
  if mode == libvim.CommandLine.ord:
    updateCommand(input, oldMode != mode)

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
  session.insert(Global, VimCommandPosition, 0)
  session.insert(Global, VimCommandCompletion, "")

  #let params = os.commandLineParams()
  #for fname in params:
  #  discard vimBufferOpen(fname, 1, 0)
  discard vimBufferOpen("src/pvim.nim", 1, 0)
