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

  ClipboardGetCallback* = proc (regname: cint; num_lines: ptr cint;
                             lines: ptr ptr ptr char_u): cint
  VoidCallback* = proc ()
  WindowSplitCallback* = proc (splitType: windowSplit_T; fname: ptr char_u)
  WindowMovementCallback* = proc (movementType: windowMovement_T; count: cint)
  YankCallback* = proc (yankInfo: ptr yankInfo_T)
  GotoCallback* = proc (gotoInfo: gotoRequest_T): cint

  lpos_T* {.bycopy.} = object
    lnum*: linenr_T            ##  line number
    col*: colnr_T              ##  column number

  buf_T* = pointer
  searchHighlight_T* {.bycopy.} = object
    start*: pos_T
    `end`*: pos_T

