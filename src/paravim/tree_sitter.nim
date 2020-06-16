{.compile: "tree_sitter/lib.c".}
{.compile: "tree_sitter/parser_javascript.c".}
{.compile: "tree_sitter/scanner_javascript.c".}
{.compile: "tree_sitter/parser_c.c".}
{.compile: "tree_sitter/parser_json.c".}
{.compile: "tree_sitter/parser_python.c".}
{.compile: "tree_sitter/scanner_python.c".}
{.compile: "tree_sitter/parser_nim.c".}
{.compile: "tree_sitter/scanner_nim.c".}

import tree_sitter/tree_sitter/api
from os import nil
from strutils import nil
from colors import nil
from buffers import nil
import tables

proc free(p: pointer) {.cdecl, importc: "free".}
proc tree_sitter_javascript(): pointer {.cdecl, importc: "tree_sitter_javascript".}
proc tree_sitter_json(): pointer {.cdecl, importc: "tree_sitter_json".}
proc tree_sitter_c(): pointer {.cdecl, importc: "tree_sitter_c".}
proc tree_sitter_python(): pointer {.cdecl, importc: "tree_sitter_python".}
proc tree_sitter_nim(): pointer {.cdecl, importc: "tree_sitter_nim".}

proc init*(path: string, lines: seq[string]): tuple[tree: pointer, parser: pointer] =
  let parser = ts_parser_new()
  let (_, _, ext) = os.splitFile(path)
  case ext:
    of ".js":
      doAssert ts_parser_set_language(parser, tree_sitter_javascript())
    of ".json":
      doAssert ts_parser_set_language(parser, tree_sitter_json())
    of ".c", ".h", ".cc", ".cpp", ".hpp":
      doAssert ts_parser_set_language(parser, tree_sitter_c())
    of ".py":
      doAssert ts_parser_set_language(parser, tree_sitter_python())
    of ".nim", ".nims", ".nimble":
      doAssert ts_parser_set_language(parser, tree_sitter_nim())
    else:
      ts_parser_delete(parser)
      return (nil, nil)
  let content = strutils.join(lines, "\n")
  (ts_parser_parse_string(parser, nil, content, content.len.uint32), parser)

proc deleteTree*(tree: pointer) =
  if tree != nil:
    ts_tree_delete(tree)

proc deleteParser*(parser: pointer) =
  if parser != nil:
    ts_parser_delete(parser)

proc echoTree*(tree: pointer) =
  if tree != nil:
    let
      node = ts_tree_root_node(tree)
      sexpr = ts_node_string(node)
    echo sexpr
    free(sexpr)
  else:
    echo "nil"

type
  Node* = tuple[kind: string, startCol: int, endCol: int]

proc parse*(node: TSNode, nodes: var Table[int, seq[Node]]) =
  let kind = $ ts_node_type(node)
  if colors.syntaxColors.hasKey(kind):
    let
      startPoint = ts_node_start_point(node)
      endPoint = ts_node_end_point(node)
    for line in startPoint.row .. endPoint.row:
      let
        lineNum = line.int
        startLine = startPoint.row.int
        endLine = endPoint.row.int
        startCol = if lineNum == startLine: startPoint.column.int else: 0
        endCol = if lineNum == endLine: endPoint.column.int else: -1
      if not nodes.hasKey(lineNum):
        nodes[lineNum] = @[]
      nodes[lineNum].add((kind, startCol, endCol))
  else:
    for i in 0 ..< ts_node_child_count(node):
      let child = ts_node_child(node, i)
      parse(child, nodes)

proc parse*(tree: pointer): Table[int, seq[Node]] =
  if tree != nil:
    let node = ts_tree_root_node(tree)
    parse(node, result)

proc getLen(arr: openArray[ref string], i: int, default: int): int =
  if i >= arr.len:
    default
  else:
    arr[i][].len

proc initInputEdit(bu: buffers.BufferUpdateTuple, lines: seq[ref string], newLines: seq[ref string]): TSInputEdit =
  let
    firstLine = bu.firstLine
    lineCountChange = bu.lineCountChange
  var edit: TSInputEdit
  for i in 0 ..< firstLine:
    edit.start_byte += lines[i][].len.uint32
  edit.start_byte += firstLine.uint32 # newlines
  edit.old_end_byte = edit.start_byte
  edit.new_end_byte = edit.start_byte
  edit.start_point.row = firstLine.uint32
  edit.start_point.column = 0.uint32
  if lineCountChange < 0:
    for i in firstLine .. firstLine + (-1 * lineCountChange):
      edit.old_end_byte += getLen(lines, i, 0).uint32
    edit.old_end_byte += uint32(-1 * lineCountChange) # newlines
    edit.new_end_byte += getLen(newLines, firstLine, 0).uint32
    edit.old_end_point.row = uint32(firstLine + (-1 * lineCountChange))
    edit.old_end_point.column = getLen(lines, firstLine + (-1 * lineCountChange), 0).uint32
    edit.new_end_point.row = firstLine.uint32
    edit.new_end_point.column = getLen(newLines, firstLine, 0).uint32
  elif lineCountChange == 0:
    let lastLine = firstLine + max(bu.lines.len - 1, 0) # bu.lines.len shouldn't ever be 0, but just in case...
    for i in firstLine .. lastLine:
      edit.old_end_byte += getLen(lines, i, 0).uint32
      edit.new_end_byte += getLen(newLines, i, 0).uint32
    edit.old_end_byte += uint32(lastLine - firstLine) # newlines
    edit.new_end_byte += uint32(lastLine - firstLine) # newlines
    edit.old_end_point.row = lastLine.uint32
    edit.old_end_point.column = getLen(lines, lastLine, 0).uint32
    edit.new_end_point.row = lastLine.uint32
    edit.new_end_point.column = getLen(newLines, lastLine, 0).uint32
  elif lineCountChange > 0:
    edit.old_end_byte += getLen(lines, firstLine, 0).uint32
    for i in firstLine .. firstLine + lineCountChange:
      edit.new_end_byte += getLen(newLines, i, 0).uint32
    edit.new_end_byte += lineCountChange.uint32 # newlines
    edit.old_end_point.row = firstLine.uint32
    edit.old_end_point.column = getLen(lines, firstLine, 0).uint32
    edit.new_end_point.row = uint32(firstLine + lineCountChange)
    edit.new_end_point.column = getLen(newLines, firstLine + lineCountChange, 0).uint32
  edit

proc editTree*(tree: pointer, parser: pointer, bu: buffers.BufferUpdateTuple, lines: seq[ref string], newLines: seq[ref string]): pointer =
  if tree != nil:
    var edit = initInputEdit(bu, lines, newLines)
    ts_tree_edit(tree, edit.addr)
    let content = strutils.join(buffers.derefStringRefs(newLines), "\n")
    result = ts_parser_parse_string(parser, tree, content, content.len.uint32)
    ts_tree_delete(tree)
