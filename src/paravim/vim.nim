import libvim, structs, core
from buffers import nil
from pararules import nil
from strutils import nil
from os import nil
from tree_sitter import nil
import tables
from unicode import nil

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
      vimInputUnicode($ vim.commandCompletion[i])

proc executeCommand() =
  let vim = pararules.query(session, rules.getVim)
  if vim.commandStart == ':' and asciiArt.hasKey(vim.commandText):
    session.insert(Global, AsciiArt, vim.commandText)
    vimInput("<Esc>")
  else:
    vimInput("<Enter>")

proc updateCommandStart(input: string) =
  const
    validCommandStarts = {':', '?', '/'}
    searchCommandStarts = {'?', '/'}
  var s = input[0]
  if not validCommandStarts.contains(s):
    s = ':'
  session.insert(Global, VimCommandStart, s)
  if searchCommandStarts.contains(s):
    session.insert(Global, VimShowSearch, true)

proc updateCommand() =
  let
    commandText = $ vimCommandLineGetText()
    commandPos = vimCommandLineGetPosition()
  session.insert(Global, VimCommandText, commandText)
  session.insert(Global, VimCommandPosition, commandPos)
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
  if vimVisualIsActive() == 1:
    var startPos, endPos: pos_T
    vimVisualGetRange(startPos.addr, endPos.addr)
    session.insert(id, VimVisualRange, (int(startPos.lnum-1), int(startPos.col), int(endPos.lnum-1), int(endPos.col)))
    session.insert(id, VimVisualBlockMode, vimVisualGetType() == 22)
  else:
    session.insert(id, VimVisualRange, (0, 0, 0, 0))

proc updateSearchHighlights(id: int) =
  let vim = pararules.query(session, rules.getVim)
  if vim.mode == libvim.CommandLine.ord and vim.commandStart == ':':
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

proc updateAfterInput() =
  let id = getCurrentSessionId()
  if id >= 0:
    session.insert(id, CursorLine, vimCursorGetLine() - 1)
    session.insert(id, CursorColumn, vimCursorGetColumn())
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
    if strutils.startsWith(input, "<") and strutils.endsWith(input, ">"):
      vimInput(input)
    else:
      vimInputUnicode(input)
  let mode = vimGetMode()
  session.insert(Global, VimMode, mode)
  if mode == libvim.CommandLine.ord:
    if mode != oldMode:
      updateCommandStart(input)
    updateCommand()
  updateAfterInput()

proc onBulkInput*(input: string) =
  vimExecute("set paste")
  for ch in unicode.utf8(input):
    if ch == "\r":
      continue
    vimInputUnicode(ch)
  vimExecute("set nopaste")
  updateAfterInput()

proc onBufDelete(buf: buf_T) =
  let bufferId = vimBufferGetId(buf)
  let index = pararules.find(session, rules.getBuffer, bufferId = bufferId)
  if index == -1:
    return
  let existingBuffer = pararules.get(session, rules.getBuffer, index)
  tree_sitter.deleteTree(existingBuffer.tree)
  tree_sitter.deleteParser(existingBuffer.parser)
  let id = existingBuffer.id
  session.retract(id, BufferId)
  session.retract(id, Lines)
  session.retract(id, CursorLine)
  session.retract(id, CursorColumn)
  session.retract(id, ScrollX)
  session.retract(id, ScrollY)
  session.retract(id, ScrollTargetX)
  session.retract(id, ScrollTargetY)
  session.retract(id, ScrollSpeedX)
  session.retract(id, ScrollSpeedY)
  session.retract(id, MaxCharCount)
  session.retract(id, LineCount)
  session.retract(id, Tree)
  session.retract(id, Parser)
  session.retract(id, VimVisualRange)
  session.retract(id, VimVisualBlockMode)
  session.retract(id, VimSearchRanges)
  if pararules.find(session, rules.getBufferEntities, id = id) != -1:
    session.retract(id, Text)
    session.retract(id, CroppedText)
    session.retract(id, MinimapText)
    session.retract(id, MinimapRects)
    session.retract(id, ShowMinimap)

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
    var lines: ref seq[string]
    new(lines)
    for i in 0 ..< count:
      let line = vimBufferGetLine(buf, linenr_T(i+1))
      lines[].add($ line)
    # get or create session id
    var sessionId: int
    if index >= 0:
      let existingBuffer = pararules.get(session, rules.getBuffer, index)
      # if the content hasn't changed, no need to update the buffer
      if existingBuffer.lines[] == lines[]:
        return
      else:
        sessionId = existingBuffer.id
        onBufDelete(buf)
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
    session.insert(sessionId, ScrollTargetX, 0f)
    session.insert(sessionId, ScrollTargetY, 0f)
    session.insert(sessionId, ScrollSpeedX, 0f)
    session.insert(sessionId, ScrollSpeedY, 0f)
    session.insert(sessionId, LineCount, count)
    let (tree, parser) = tree_sitter.init(pathStr, lines[])
    session.insert(sessionId, Tree, tree)
    session.insert(sessionId, Parser, parser)
    session.insert(sessionId, VimVisualRange, (0, 0, 0, 0))
    session.insert(sessionId, VimVisualBlockMode, false)
    session.insert(sessionId, VimSearchRanges, @[])
    session.insert(sessionId, ShowMinimap, false)
    let parsed = tree_sitter.parse(tree, lines[].len)
    insertTextEntity(sessionId, lines, parsed)

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
  let id = vimBufferGetId(bufferUpdate.buf).int
  # get current buffer
  let index = pararules.find(session, rules.getBuffer, bufferId = id)
  if index == -1:
    return
  let buffer = pararules.get(session, rules.getBuffer, index) # will throw if buffer isn't in session
  # update the lines
  let bu = (lines, firstLine.int, bufferUpdate.xtra.int)
  var newLines = buffers.updateLines(buffer.lines, bu)
  # if the lines are empty, insert a single blank line
  # vim seems to always want there to be at least one line
  # see test: delete all lines
  if newLines[].len == 0:
    newLines[] = @[""]
  session.insert(buffer.id, Lines, newLines)
  # re-parse if necessary
  let
    newTree = tree_sitter.editTree(buffer.tree, buffer.parser, newLines)
    parsed = tree_sitter.parse(newTree, newLines[].len)
  session.insert(buffer.id, Tree, newTree)
  pararules.fireRules(session) # fire rules manually so the following query gets the latest data
  # update text entity
  block:
    let index = pararules.find(session, rules.getBufferEntities, id = buffer.id)
    if index == -1:
      return
    let bufferEntities = pararules.get(session, rules.getBufferEntities, index)
    updateTextEntity(buffer.id, newLines, parsed, bufferEntities.text, bu)

proc onStopSearch() {.cdecl.} =
  session.insert(Global, VimShowSearch, false)

proc onMessage(title: ptr char_u; msg: ptr char_u; priority: msgPriority_T) {.cdecl.} =
  session.insert(Global, VimMessage, $ msg)

proc init*(onQuit: QuitCallback, onYank: YankCallback) =
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
  session.insert(Global, VimCommandStart, ':')
  session.insert(Global, VimCommandPosition, 0)
  session.insert(Global, VimCommandCompletion, "")
  session.insert(Global, VimMessage, "")
  session.insert(Global, VimShowSearch, false)
