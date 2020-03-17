{.compile: "tree_sitter/lib.c".}
{.compile: "tree_sitter/parser_javascript.c".}
{.compile: "tree_sitter/parser_javascript_scanner.c".}
{.compile: "tree_sitter/parser_c.c".}

import tree_sitter/tree_sitter/api
from os import nil
from strutils import nil
from algorithm import nil
from colors import nil
import tables

proc free(p: pointer) {.cdecl, importc: "free".}
proc tree_sitter_javascript(): pointer {.cdecl, importc: "tree_sitter_javascript".}
proc tree_sitter_c(): pointer {.cdecl, importc: "tree_sitter_c".}

proc init*(path: string, lines: seq[string]): tuple[tree: pointer, parser: pointer] =
  let parser = ts_parser_new()
  let (_, _, ext) = os.splitFile(path)
  case ext:
    of ".js":
      doAssert ts_parser_set_language(parser, tree_sitter_javascript())
    of ".c", ".h":
      doAssert ts_parser_set_language(parser, tree_sitter_c())
    else:
      ts_parser_delete(parser)
      return (nil, nil)
  let content = strutils.join(lines, "\n")
  (ts_parser_parse_string(parser, nil, content, content.len.uint32), parser)

proc deleteTree*(tree: pointer) =
  if tree != nil:
    ts_tree_delete(tree)

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
  Node* = tuple[kind: string, startByte: int, endByte: int]

proc parse*(node: TSNode, nodes: var seq[Node]) =
  let kind = $ ts_node_type(node)
  if colors.syntaxColors.hasKey(kind):
    nodes.add((kind, ts_node_start_byte(node).int, ts_node_end_byte(node).int))
  else:
    for i in 0 ..< ts_node_child_count(node):
      let child = ts_node_child(node, i)
      parse(child, nodes)

proc parse*(tree: pointer): seq[Node] =
  if tree != nil:
    let node = ts_tree_root_node(tree)
    parse(node, result)
    algorithm.sort(result, proc (x, y: Node): int =
      if x.startByte < y.startByte: -1
      elif x.startByte > y.startByte: 1
      else: 0)

proc getLen(arr: openArray[string], i: int, default: int): int =
  if i >= arr.len:
    default
  else:
    arr[i].len

proc initInputEdit(firstLine: int, lineCountChange: int, lines: seq[string], newLines: seq[string]): TSInputEdit =
  var edit: TSInputEdit
  for i in 0 ..< firstLine:
    edit.start_byte += lines[i].len.uint32
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
    edit.old_end_byte += getLen(lines, firstLine, 0).uint32
    edit.new_end_byte += getLen(newLines, firstLine, 0).uint32
    edit.old_end_point.row = firstLine.uint32
    edit.old_end_point.column = getLen(lines, firstLine, 0).uint32
    edit.new_end_point.row = firstLine.uint32
    edit.new_end_point.column = getLen(newLines, firstLine, 0).uint32
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

proc editTree*(tree: pointer, parser: pointer, firstLine: int, lineCountChange: int, lines: seq[string], newLines: seq[string]): pointer =
  if tree != nil:
    var edit = initInputEdit(firstLine, lineCountChange, lines, newLines)
    ts_tree_edit(tree, edit.addr)
    let content = strutils.join(newLines, "\n")
    result = ts_parser_parse_string(parser, tree, content, content.len.uint32)
    ts_tree_delete(tree)
