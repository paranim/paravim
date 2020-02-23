type
  linenr_T* = clong
  colnr_T* = cint
  short_u* = cushort
  char_u* = cuchar

  pos_T* {.bycopy.} = object
    lnum*: linenr_T            ##  line number
    col*: colnr_T              ##  column number
    coladd*: colnr_T           ##  extra virtual column

  msgPriority_T* = enum
    MSG_INFO, MSG_WARNING, MSG_ERROR
  windowSplit_T* = enum
    HORIZONTAL_SPLIT, VERTICAL_SPLIT, TAB_PAGE
  windowMovement_T* = enum
    WIN_CURSOR_LEFT,          ##  <C-w>h
    WIN_CURSOR_RIGHT,         ##  <C-w>l
    WIN_CURSOR_UP,            ##  <C-w>k
    WIN_CURSOR_DOWN,          ##  <C-w>j
    WIN_MOVE_FULL_LEFT,       ##  <C-w>H
    WIN_MOVE_FULL_RIGHT,      ##  <C-w>L
    WIN_MOVE_FULL_UP,         ##  <C-w>K
    WIN_MOVE_FULL_DOWN,       ##  <C-w>J
    WIN_CURSOR_TOP_LEFT,      ##  <C-w>t
    WIN_CURSOR_BOTTOM_RIGHT,  ##  <C-w>b
    WIN_CURSOR_PREVIOUS,      ##  <C-w>p
    WIN_MOVE_ROTATE_DOWNWARDS, ##  <C-w>r
    WIN_MOVE_ROTATE_UPWARDS   ##  <C-w>R

  yankInfo_T* {.bycopy.} = object
    op_char*: cint
    extra_op_char*: cint
    regname*: cint
    blockType*: cint           ##  MLINE, MCHAR, MBLOCK
    start*: pos_T
    `end`*: pos_T
    numLines*: cint
    lines*: ptr ptr char_u

  gotoTarget_T* = enum
    DEFINITION, DECLARATION, IMPLEMENTATION, TYPEDEFINITION
  gotoRequest_T* {.bycopy.} = object
    location*: pos_T
    target*: gotoTarget_T

  ClipboardGetCallback* = proc (regname: cint; num_lines: ptr cint; lines: ptr ptr ptr char_u): cint {.cdecl.}
  VoidCallback* = proc () {.cdecl.}
  WindowSplitCallback* = proc (splitType: windowSplit_T; fname: ptr char_u) {.cdecl.}
  WindowMovementCallback* = proc (movementType: windowMovement_T; count: cint) {.cdecl.}
  YankCallback* = proc (yankInfo: ptr yankInfo_T) {.cdecl.}
  GotoCallback* = proc (gotoInfo: gotoRequest_T): cint {.cdecl.}

  lpos_T* {.bycopy.} = object
    lnum*: linenr_T            ##  line number
    col*: colnr_T              ##  column number

  buf_T* = pointer
  searchHighlight_T* {.bycopy.} = object
    start*: pos_T
    `end`*: pos_T

  bufferUpdate_T* {.bycopy.} = object
    buf*: buf_T
    lnum*: linenr_T            ##  first line with change
    lnume*: linenr_T           ##  line below last changed line
    xtra*: clong               ##  number of extra lines (negative when deleting)

  writeFailureReason_T* = enum
    FILE_CHANGED
  BufferUpdateCallback* = proc (bufferUpdate: bufferUpdate_T) {.cdecl.}
  FileWriteFailureCallback* = proc (failureReason: writeFailureReason_T; buf: buf_T) {.cdecl.}
  MessageCallback* = proc (title: ptr char_u; msg: ptr char_u; priority: msgPriority_T) {.cdecl.}
  DirectoryChangedCallback* = proc (path: ptr char_u) {.cdecl.}
  QuitCallback* = proc (buf: buf_T; isForced: cint) {.cdecl.}

  event_T* = enum
    EVENT_BUFADD,             ##  after adding a buffer to the buffer list
    EVENT_BUFDELETE,          ##  deleting a buffer from the buffer list
    EVENT_BUFENTER,           ##  after entering a buffer
    EVENT_BUFFILEPOST,        ##  after renaming a buffer
    EVENT_BUFFILEPRE,         ##  before renaming a buffer
    EVENT_BUFHIDDEN,          ##  just after buffer becomes hidden
    EVENT_BUFLEAVE,           ##  before leaving a buffer
    EVENT_BUFNEW,             ##  after creating any buffer
    EVENT_BUFNEWFILE,         ##  when creating a buffer for a new file
    EVENT_BUFREADCMD,         ##  read buffer using command
    EVENT_BUFREADPOST,        ##  after reading a buffer
    EVENT_BUFREADPRE,         ##  before reading a buffer
    EVENT_BUFUNLOAD,          ##  just before unloading a buffer
    EVENT_BUFWINENTER,        ##  after showing a buffer in a window
    EVENT_BUFWINLEAVE,        ##  just after buffer removed from window
    EVENT_BUFWIPEOUT,         ##  just before really deleting a buffer
    EVENT_BUFWRITECMD,        ##  write buffer using command
    EVENT_BUFWRITEPOST,       ##  after writing a buffer
    EVENT_BUFWRITEPRE,        ##  before writing a buffer
    EVENT_CMDLINECHANGED,     ##  command line was modified
    EVENT_CMDLINEENTER,       ##  after entering the command line
    EVENT_CMDLINELEAVE,       ##  before leaving the command line
    EVENT_CMDUNDEFINED,       ##  command undefined
    EVENT_CMDWINENTER,        ##  after entering the cmdline window
    EVENT_CMDWINLEAVE,        ##  before leaving the cmdline window
    EVENT_COLORSCHEME,        ##  after loading a colorscheme
    EVENT_COLORSCHEMEPRE,     ##  before loading a colorscheme
    EVENT_COMPLETECHANGED,    ##  after completion popup menu changed
    EVENT_COMPLETEDONE,       ##  after finishing insert complete
    EVENT_CURSORHOLD,         ##  cursor in same position for a while
    EVENT_CURSORHOLDI,        ##  idem, in Insert mode
    EVENT_CURSORMOVED,        ##  cursor was moved
    EVENT_CURSORMOVEDI,       ##  cursor was moved in Insert mode
    EVENT_DIFFUPDATED,        ##  after diffs were updated
    EVENT_DIRCHANGED,         ##  after user changed directory
    EVENT_ENCODINGCHANGED,    ##  after changing the 'encoding' option
    EVENT_EXITPRE,            ##  before exiting
    EVENT_FILEAPPENDCMD,      ##  append to a file using command
    EVENT_FILEAPPENDPOST,     ##  after appending to a file
    EVENT_FILEAPPENDPRE,      ##  before appending to a file
    EVENT_FILECHANGEDRO,      ##  before first change to read-only file
    EVENT_FILECHANGEDSHELL,   ##  after shell command that changed file
    EVENT_FILECHANGEDSHELLPOST, ##  after (not) reloading changed file
    EVENT_FILEREADCMD,        ##  read from a file using command
    EVENT_FILEREADPOST,       ##  after reading a file
    EVENT_FILEREADPRE,        ##  before reading a file
    EVENT_FILETYPE,           ##  new file type detected (user defined)
    EVENT_FILEWRITECMD,       ##  write to a file using command
    EVENT_FILEWRITEPOST,      ##  after writing a file
    EVENT_FILEWRITEPRE,       ##  before writing a file
    EVENT_FILTERREADPOST,     ##  after reading from a filter
    EVENT_FILTERREADPRE,      ##  before reading from a filter
    EVENT_FILTERWRITEPOST,    ##  after writing to a filter
    EVENT_FILTERWRITEPRE,     ##  before writing to a filter
    EVENT_FOCUSGAINED,        ##  got the focus
    EVENT_FOCUSLOST,          ##  lost the focus to another app
    EVENT_FUNCUNDEFINED,      ##  if calling a function which doesn't exist
    EVENT_GUIENTER,           ##  after starting the GUI
    EVENT_GUIFAILED,          ##  after starting the GUI failed
    EVENT_INSERTCHANGE,       ##  when changing Insert/Replace mode
    EVENT_INSERTCHARPRE,      ##  before inserting a char
    EVENT_INSERTENTER,        ##  when entering Insert mode
    EVENT_INSERTLEAVE,        ##  when leaving Insert mode
    EVENT_MENUPOPUP,          ##  just before popup menu is displayed
    EVENT_OPTIONSET,          ##  option was set
    EVENT_QUICKFIXCMDPOST,    ##  after :make, :grep etc.
    EVENT_QUICKFIXCMDPRE,     ##  before :make, :grep etc.
    EVENT_QUITPRE,            ##  before :quit
    EVENT_REMOTEREPLY,        ##  upon string reception from a remote vim
    EVENT_SESSIONLOADPOST,    ##  after loading a session file
    EVENT_SHELLCMDPOST,       ##  after ":!cmd"
    EVENT_SHELLFILTERPOST,    ##  after ":1,2!cmd", ":w !cmd", ":r !cmd".
    EVENT_SOURCECMD,          ##  sourcing a Vim script using command
    EVENT_SOURCEPRE,          ##  before sourcing a Vim script
    EVENT_SOURCEPOST,         ##  after sourcing a Vim script
    EVENT_SPELLFILEMISSING,   ##  spell file missing
    EVENT_STDINREADPOST,      ##  after reading from stdin
    EVENT_STDINREADPRE,       ##  before reading from stdin
    EVENT_SWAPEXISTS,         ##  found existing swap file
    EVENT_SYNTAX,             ##  syntax selected
    EVENT_TABCLOSED,          ##  after closing a tab page
    EVENT_TABENTER,           ##  after entering a tab page
    EVENT_TABLEAVE,           ##  before leaving a tab page
    EVENT_TABNEW,             ##  when entering a new tab page
    EVENT_TERMCHANGED,        ##  after changing 'term'
    EVENT_TERMINALOPEN,       ##  after a terminal buffer was created
    EVENT_TERMRESPONSE,       ##  after setting "v:termresponse"
    EVENT_TEXTCHANGED,        ##  text was modified not in Insert mode
    EVENT_TEXTCHANGEDI,       ##  text was modified in Insert mode
    EVENT_TEXTCHANGEDP,       ##  TextChangedI with popup menu visible
    EVENT_TEXTYANKPOST,       ##  after some text was yanked
    EVENT_USER,               ##  user defined autocommand
    EVENT_VIMENTER,           ##  after starting Vim
    EVENT_VIMLEAVE,           ##  before exiting Vim
    EVENT_VIMLEAVEPRE,        ##  before exiting Vim and writing .viminfo
    EVENT_VIMRESIZED,         ##  after Vim window was resized
    EVENT_WINENTER,           ##  after entering a window
    EVENT_WINLEAVE,           ##  before leaving a window
    EVENT_WINNEW,             ##  when entering a new window
    NUM_EVENTS                ##  MUST be the last one

  AutoCommandCallback* = proc (a1: event_T; buf: buf_T) {.cdecl.}

