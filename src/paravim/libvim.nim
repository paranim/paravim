import structs
import os

proc getLib(): string =
  const extension =
    when defined(windows):
      "dll"
    elif defined(macosx):
      "dylib"
    elif defined(linux):
      "so"
  let pvimpath = getAppDir().joinPath("pvimpkg").joinPath("bin").joinPath("libvim." & extension)
  if existsFile(pvimpath):
    pvimpath
  else:
    currentSourcePath().parentDir().joinPath("bin").joinPath("libvim." & extension)

when not defined(paravim_static):
  {.push dynlib: getLib().}

type
  Mode* = enum
    Normal = 0x01,
    Visual = 0x02
    OpPending = 0x04,
    CommandLine = 0x08,
    Insert = 0x10,
    Replace = 0x50,
    NormalBusy = 0x100 + 0x01,

##  libvim.c
##
##  vimInit
##
##  This must be called prior to using any other methods.
##
##  This expects an `argc` and an `argv` parameters,
##  for the command line arguments for this vim instance.
##

proc vimInit*(argc: cint; argv: cstringArray){.cdecl, importc.}
## **
##  Buffer Methods
## *
##
##  vimBufferOpen
##
##  Open a buffer and set as current.
##

proc vimBufferOpen*(ffname_arg: cstring; lnum: linenr_T; flags: cint): buf_T {.cdecl, importc.}
##
##  vimBufferCheckIfChanged
##
##  Check if the contents of a buffer have been changed on the filesystem, outside of libvim.
##  Returns 1 if buffer was changed (and changes the buffer contents)
##  Returns 2 if a message was displayed
##  Returns 0 otherwise
##

#proc vimBufferCheckIfChanged*(buf: buf_T): cint
#proc vimBufferGetById*(id: cint): buf_T
proc vimBufferGetCurrent*(): buf_T {.cdecl, importc.}
#proc vimBufferSetCurrent*(buf: buf_T)
proc vimBufferGetFilename*(buf: buf_T): ptr char_u {.cdecl, importc.}
#proc vimBufferGetFiletype*(buf: buf_T): ptr char_u
proc vimBufferGetId*(buf: buf_T): cint {.cdecl, importc.}
#proc vimBufferGetLastChangedTick*(buf: buf_T): clong
proc vimBufferGetLine*(buf: buf_T; lnum: linenr_T): ptr char_u {.cdecl, importc.}
proc vimBufferGetLineCount*(buf: buf_T): csize {.cdecl, importc.}
##
##  vimBufferSetLines
##
##  Set a range of lines from the one-based start line to one-based end, inclusive.
##
##  Examples:
##  vimBufferSetLine(buf, 1, 1, ["abc"]); // Set line 1 to "abc""
##  vimBufferSetLine(buf, 1, 2, ["abc"]); // Remove line 2, set line 1 to "abc"
##  vimBufferSetLine(buf, 0, 0, ["def"]); // Insert "def" before the contents of the buffer
##

proc vimBufferSetLines*(buf: buf_T; start: linenr_T; `end`: linenr_T;
                        lines: cstringArray; count: cint) {.cdecl, importc.}
#proc vimBufferGetModified*(buf: buf_T): cint
proc vimSetBufferUpdateCallback*(bufferUpdate: BufferUpdateCallback) {.cdecl, importc.}
## **
##  Autocommands
## *

proc vimSetAutoCommandCallback*(autoCommandDispatch: AutoCommandCallback) {.cdecl, importc.}
## *
##  Commandline
## *

#proc vimCommandLineGetType*(): char_u
proc vimCommandLineGetText*(): ptr char_u {.cdecl, importc.}
proc vimCommandLineGetPosition*(): cint {.cdecl, importc.}
proc vimCommandLineGetCompletions*(completions: ptr cstringArray; count: ptr cint) {.cdecl, importc.}
## **
##  Cursor Methods
## *

proc vimCursorGetColumn*(): colnr_T {.cdecl, importc.}
proc vimCursorGetLine*(): linenr_T {.cdecl, importc.}
#proc vimCursorGetPosition*(): pos_T
proc vimCursorSetPosition*(pos: pos_T) {.cdecl, importc.}
## **
##  vimCursorGetDesiredColumn
##
##  Get the column that we'd like to be at - used to stay in the same
##  column for up/down cursor motions.
##

#proc vimCursorGetDesiredColumn*(): colnr_T
## **
##  File I/O
## *

#proc vimSetFileWriteFailureCallback*(fileWriteFailureCallback: FileWriteFailureCallback)
## **
##  User Input
## *

proc vimInput*(input: cstring) {.cdecl, importc: "vimKey".}
proc vimInputUnicode*(input: cstring) {.cdecl, importc: "vimInput".}
proc vimExecute*(cmd: cstring) {.cdecl, importc.}
## **
##  Messages
## *

proc vimSetMessageCallback*(messageCallback: MessageCallback) {.cdecl, importc.}
## *
##  Misc
##

#proc vimSetGotoCallback*(gotoCallback: GotoCallback)
#proc vimSetDirectoryChangedCallback*(callback: DirectoryChangedCallback)
##
##  vimSetQuitCallback
##
##  Called when a `:q`, `:qa`, `:q!` is called
##
##  It is up to the libvim consumer how to handle the 'quit' call.
##  There are two arguments passed:
##  - `buffer`: the buffer quit was requested for
##  - `force`: a boolean if the command was forced (ie, if `q!` was used)
##

proc vimSetQuitCallback*(callback: QuitCallback) {.cdecl, importc.}
##
##  vimSetUnhandledEscapeCallback
##
##  Called when <esc> is pressed in normal mode, but there is no
##  pending operator or action.
##
##  This is intended for UI's to pick up and handle (for example,
##  to clear messages or alerts).
##

proc vimSetUnhandledEscapeCallback*(callback: VoidCallback) {.cdecl, importc.}
## **
##  Options
##

proc vimOptionSetTabSize*(tabSize: cint) {.cdecl, importc.}
proc vimOptionSetInsertSpaces*(insertSpaces: cint) {.cdecl, importc.}
proc vimOptionGetInsertSpaces*(): cint {.cdecl, importc.}
proc vimOptionGetTabSize*(): cint {.cdecl, importc.}
## **
##  Registers
## *

#proc vimRegisterGet*(reg_name: cint; num_lines: ptr cint; lines: ptr ptr ptr char_u)
## **
##  Undo
## *

#proc vimUndoSaveCursor*(): cint
#proc vimUndoSaveRegion*(start_lnum: linenr_T; end_lnum: linenr_T): cint
## **
##  Visual Mode
## *

proc vimVisualGetType*(): cint {.cdecl, importc.}
proc vimVisualIsActive*(): cint {.cdecl, importc.}
#proc vimSelectIsActive*(): cint
##
##  vimVisualGetRange
##
##  If in visual mode or select mode, returns the current range.
##  If not in visual or select mode, returns the last visual range.
##

proc vimVisualGetRange*(startPos: ptr pos_T; endPos: ptr pos_T) {.cdecl, importc.}
## **
##  Search
## *
##
##  vimSearchGetMatchingPair
##
##  Returns the position of a matching pair,
##  based on the current buffer and cursor position
##
##  result is NULL if no match found.
##

#proc vimSearchGetMatchingPair*(initc: cint): ptr pos_T
##
##  vimSearchGetHighlights
##
##  Get highlights for the current search
##

proc vimSearchGetHighlights*(start_lnum: linenr_T; end_lnum: linenr_T;
                             num_highlights: ptr cint;
                             highlights: ptr ptr searchHighlight_T) {.cdecl, importc.}
##
##  vimSearchGetPattern
##
##  Get the current search pattern
##

#proc vimSearchGetPattern*(): ptr char_u
proc vimSetStopSearchHighlightCallback*(callback: VoidCallback) {.cdecl, importc.}
## **
##  Window
##

#proc vimWindowGetWidth*(): cint
#proc vimWindowGetHeight*(): cint
#proc vimWindowGetTopLine*(): cint
#proc vimWindowGetLeftColumn*(): cint
proc vimWindowSetWidth*(width: cint) {.cdecl, importc.}
proc vimWindowSetHeight*(height: cint) {.cdecl, importc.}
#proc vimWindowSetTopLeft*(top: cint; left: cint)
#proc vimSetWindowSplitCallback*(callback: WindowSplitCallback)
#proc vimSetWindowMovementCallback*(callback: WindowMovementCallback)
## **
##  Misc
## *

#proc vimSetClipboardGetCallback*(callback: ClipboardGetCallback)
proc vimGetMode*(): cint {.cdecl, importc.}
proc vimSetYankCallback*(callback: YankCallback) {.cdecl, importc.}
##  Callbacks for when the `:intro` and `:version` commands are used
##
##   The Vim license has some specific requirements when implementing these methods:
##
##     3) A message must be added, at least in the output of the ":version"
##        command and in the intro screen, such that the user of the modified Vim
##        is able to see that it was modified.  When distributing as mentioned
##        under 2)e) adding the message is only required for as far as this does
##        not conflict with the license used for the changes.
##

#proc vimSetDisplayIntroCallback*(callback: VoidCallback)
#proc vimSetDisplayVersionCallback*(callback: VoidCallback)

proc vimFree*(p: pointer) {.cdecl, importc: "vim_free".}
