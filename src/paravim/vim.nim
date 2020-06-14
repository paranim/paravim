import libvim, structs, core
from buffers import nil
from pararules import nil
from strutils import nil
from os import nil
from tree_sitter import nil
import tables

proc cropCommandText(commandText: string): string =
  result = ""
  let index = strutils.find(commandText, ' ')
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
  if vim.commandStart == ":" and asciiArt.hasKey(vim.commandText):
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
    let s = if not validCommandStarts.contains(input[0]): ":" else: input
    session.insert(Global, VimCommandStart, s)
    if s != ":":
      session.insert(Global, VimShowSearch, true)
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
      let firstPart = cropCommandText(commandText)
      completion = firstPart & $ completions[0]
    for i in 0 ..< count:
      vimFree(completions[i])
  session.insert(Global, VimCommandCompletion, completion)

proc updateSelection(id: int) =
  if id >= 0:
    if vimVisualIsActive() == 1:
      var startPos, endPos: pos_T
      vimVisualGetRange(startPos.addr, endPos.addr)
      session.insert(id, VimVisualRange, (int(startPos.lnum-1), int(startPos.col), int(endPos.lnum-1), int(endPos.col)))
      session.insert(id, VimVisualBlockMode, vimVisualGetType() == 22)
    else:
      session.insert(id, VimVisualRange, (0, 0, 0, 0))

proc updateSearchHighlights(id: int) =
  if id >= 0:
    let vim = pararules.query(session, rules.getVim)
    if vim.mode == libvim.CommandLine.ord and vim.commandStart == ":":
      return
    var
      numHighlights: cint
      highlights: ptr searchHighlight_T
      ranges: seq[buffers.RangeTuple]
    vimSearchGetHighlights(1, vimBufferGetLineCount(vimBufferGetCurrent()).clong, numHighlights.addr, highlights.addr)
    let arr = cast[ptr UncheckedArray[searchHighlight_T]](highlights)
    for i in 0 ..< numHighlights:
      ranges.add((
        startLine: int(arr[i].start.lnum-1),
        startColumn: int(arr[i].start.col),
        endLine: int(arr[i].`end`.lnum-1),
        endColumn: int(arr[i].`end`.col)
      ))
    vimFree(highlights)
    session.insert(id, VimSearchRanges, ranges)

proc updateAfterInput(input: string, oldMode: int) =
  let mode = vimGetMode()
  session.insert(Global, VimMode, mode)
  let id = getCurrentSessionId()
  if id >= 0:
    session.insert(id, CursorLine, vimCursorGetLine() - 1)
    session.insert(id, CursorColumn, vimCursorGetColumn())
  if mode == libvim.CommandLine.ord:
    updateCommand(input, oldMode != mode)
  updateSelection(id)
  updateSearchHighlights(id)

proc onInput*(input: string) =
  session.insert(Global, VimMessage, "") # clear any pre-existing message
  let oldMode = vimGetMode()
  if oldMode == libvim.CommandLine.ord and input == "<Tab>":
    completeCommand()
  elif oldMode == libvim.CommandLine.ord and input == "<Enter>":
    executeCommand()
  else:
    session.insert(Global, AsciiArt, "")
    vimInput(input)
  updateAfterInput(input, oldMode)

proc onBulkInput*(input: string) =
  let oldMode = vimGetMode()
  vimExecute("set paste")
  for ch in input:
    if ch == '\r':
      continue
    vimInput($ ch)
  vimExecute("set nopaste")
  updateAfterInput(input, oldMode)

proc onBufEnter(buf: buf_T) =
  let
    bufferId = vimBufferGetId(buf)
    path = vimBufferGetFilename(buf)
    count = vimBufferGetLineCount(buf)
  session.insert(Global, CurrentBufferId, bufferId)
  session.insert(Global, WindowTitle, if path == nil: "Paravim" else: os.extractFilename($ path) & " - Paravim")
  let index = pararules.find(session, rules.getBuffer, bufferId = bufferId)
  if path != nil:
    let pathStr = $ path
    # get lines
    var lines: seq[string]
    for i in 0 ..< count:
      let line = vimBufferGetLine(buf, linenr_T(i+1))
      lines.add($ line)
    # get or create session id
    var sessionId: int
    if index >= 0:
      let existingBuffer = pararules.get(session, rules.getBuffer, index)
      # if the content hasn't changed, no need to update the buffer
      if existingBuffer.lines == lines:
        return
      else:
        sessionId = existingBuffer.id
        session.insert(Global, DeleteBuffer, bufferId)
        session.retract(Global, DeleteBuffer, bufferId)
    else:
      sessionId = nextId
      nextId += 1
    # insert buffer
    session.insert(sessionId, BufferId, bufferId)
    session.insert(sessionId, Path, pathStr)
    session.insert(sessionId, Lines, lines)
    session.insert(sessionId, CursorLine, vimCursorGetLine() - 1)
    session.insert(sessionId, CursorColumn, vimCursorGetColumn())
    session.insert(sessionId, ScrollX, 0f)
    session.insert(sessionId, ScrollY, 0f)
    session.insert(sessionId, LineCount, count)
    let (tree, parser) = tree_sitter.init(pathStr, lines)
    session.insert(sessionId, Tree, tree)
    session.insert(sessionId, Parser, parser)
    session.insert(sessionId, VimVisualRange, (0, 0, 0, 0))
    session.insert(sessionId, VimVisualBlockMode, false)
    session.insert(sessionId, VimSearchRanges, @[])

proc onBufDelete(buf: buf_T) =
  let bufferId = vimBufferGetId(buf)
  session.insert(Global, DeleteBuffer, bufferId)
  session.retract(Global, DeleteBuffer, bufferId)

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

proc onStopSearch() {.cdecl.} =
  session.insert(Global, VimShowSearch, false)

proc onMessage(title: ptr char_u; msg: ptr char_u; priority: msgPriority_T) {.cdecl.} =
  session.insert(Global, VimMessage, $ msg)

proc init*(filesToOpen: seq[string], onQuit: QuitCallback, onYank: YankCallback) =
  vimSetAutoCommandCallback(onAutoCommand)
  vimSetBufferUpdateCallback(onBufferUpdate)
  vimSetQuitCallback(onQuit)
  vimSetStopSearchHighlightCallback(onStopSearch)
  vimSetUnhandledEscapeCallback(onStopSearch)
  vimSetMessageCallback(onMessage)
  vimSetYankCallback(onYank)

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
  vimExecute("set fileformats=unix,dos")
  vimExecute("filetype plugin index on")

  session.insert(Global, VimMode, vimGetMode())
  session.insert(Global, VimCommandText, "")
  session.insert(Global, VimCommandStart, "")
  session.insert(Global, VimCommandPosition, 0)
  session.insert(Global, VimCommandCompletion, "")
  session.insert(Global, VimMessage, "")
  session.insert(Global, VimShowSearch, false)

  for fname in filesToOpen:
    discard vimBufferOpen(fname, 1, 0)
