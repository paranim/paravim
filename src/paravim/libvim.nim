import structs

const dllname =
  when defined(windows):
    when defined(paravimtest):
      "src/paravim/libvim.dll"
    else:
      "paravim/libvim.dll"
  elif defined(macosx):
    when defined(paravimtest):
      "src/paravim/libvim.dylib"
    else:
      "paravim/libvim.dylib"
  elif defined(linux):
    when defined(paravimtest):
      "src/paravim/libvim.so"
    else:
      "paravim/libvim.so"

##  libvim.c
##
##  vimInit
##
##  This must be called prior to using any other methods.
##
##  This expects an `argc` and an `argv` parameters,
##  for the command line arguments for this vim instance.
##

proc vimInit*(argc: cint; argv: cstringArray){.cdecl, dynlib: dllname, importc: "vimInit".}
## **
##  Buffer Methods
## *
##
##  vimBufferOpen
##
##  Open a buffer and set as current.
##

proc vimBufferOpen*(ffname_arg: cstring; lnum: linenr_T; flags: cint): ptr buf_T {.cdecl, dynlib: dllname, importc: "vimBufferOpen".}
##
##  vimBufferCheckIfChanged
##
##  Check if the contents of a buffer have been changed on the filesystem, outside of libvim.
##  Returns 1 if buffer was changed (and changes the buffer contents)
##  Returns 2 if a message was displayed
##  Returns 0 otherwise
##

#proc vimBufferCheckIfChanged*(buf: ptr buf_T): cint
#proc vimBufferGetById*(id: cint): ptr buf_T
#proc vimBufferGetCurrent*(): ptr buf_T
#proc vimBufferSetCurrent*(buf: ptr buf_T)
#proc vimBufferGetFilename*(buf: ptr buf_T): ptr char_u
#proc vimBufferGetFiletype*(buf: ptr buf_T): ptr char_u
#proc vimBufferGetId*(buf: ptr buf_T): cint
#proc vimBufferGetLastChangedTick*(buf: ptr buf_T): clong
#proc vimBufferGetLine*(buf: ptr buf_T; lnum: linenr_T): ptr char_u
#proc vimBufferGetLineCount*(buf: ptr buf_T): csize
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

#proc vimBufferSetLines*(buf: ptr buf_T; start: linenr_T; `end`: linenr_T;
#                       lines: ptr ptr char_u; count: cint)
#proc vimBufferGetModified*(buf: ptr buf_T): cint
#proc vimSetBufferUpdateCallback*(bufferUpdate: BufferUpdateCallback)
## **
##  Autocommands
## *

#proc vimSetAutoCommandCallback*(autoCommandDispatch: AutoCommandCallback)
## *
##  Commandline
## *

#proc vimCommandLineGetType*(): char_u
#proc vimCommandLineGetText*(): ptr char_u
#proc vimCommandLineGetPosition*(): cint
#proc vimCommandLineGetCompletions*(completions: ptr ptr ptr char_u; count: ptr cint)
## **
##  Cursor Methods
## *

#proc vimCursorGetColumn*(): colnr_T
#proc vimCursorGetLine*(): linenr_T
#proc vimCursorGetPosition*(): pos_T
#proc vimCursorSetPosition*(pos: pos_T)
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

#proc vimInput*(input: ptr char_u)
#proc vimExecute*(cmd: ptr char_u)
## **
##  Messages
## *

#proc vimSetMessageCallback*(messageCallback: MessageCallback)
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

#proc vimSetQuitCallback*(callback: QuitCallback)
##
##  vimSetUnhandledEscapeCallback
##
##  Called when <esc> is pressed in normal mode, but there is no
##  pending operator or action.
##
##  This is intended for UI's to pick up and handle (for example,
##  to clear messages or alerts).
##

#proc vimSetUnhandledEscapeCallback*(callback: VoidCallback)
## **
##  Options
##

proc vimOptionSetTabSize*(tabSize: cint) {.cdecl, dynlib: dllname, importc: "vimOptionSetTabSize".}
proc vimOptionSetInsertSpaces*(insertSpaces: cint) {.cdecl, dynlib: dllname, importc: "vimOptionSetInsertSpaces".}
proc vimOptionGetInsertSpaces*(): cint {.cdecl, dynlib: dllname, importc: "vimOptionGetInsertSpaces".}
proc vimOptionGetTabSize*(): cint {.cdecl, dynlib: dllname, importc: "vimOptionGetTabSize".}
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

#proc vimVisualGetType*(): cint
#proc vimVisualIsActive*(): cint
#proc vimSelectIsActive*(): cint
##
##  vimVisualGetRange
##
##  If in visual mode or select mode, returns the current range.
##  If not in visual or select mode, returns the last visual range.
##

#proc vimVisualGetRange*(startPos: ptr pos_T; endPos: ptr pos_T)
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

#proc vimSearchGetHighlights*(start_lnum: linenr_T; end_lnum: linenr_T;
#                            num_highlights: ptr cint;
#                            highlights: ptr ptr searchHighlight_T)
##
##  vimSearchGetPattern
##
##  Get the current search pattern
##

#proc vimSearchGetPattern*(): ptr char_u
#proc vimSetStopSearchHighlightCallback*(callback: VoidCallback)
## **
##  Window
##

#proc vimWindowGetWidth*(): cint
#proc vimWindowGetHeight*(): cint
#proc vimWindowGetTopLine*(): cint
#proc vimWindowGetLeftColumn*(): cint
#proc vimWindowSetWidth*(width: cint)
#proc vimWindowSetHeight*(height: cint)
#proc vimWindowSetTopLeft*(top: cint; left: cint)
#proc vimSetWindowSplitCallback*(callback: WindowSplitCallback)
#proc vimSetWindowMovementCallback*(callback: WindowMovementCallback)
## **
##  Misc
## *

#proc vimSetClipboardGetCallback*(callback: ClipboardGetCallback)
#proc vimGetMode*(): cint
#proc vimSetYankCallback*(callback: YankCallback)
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
