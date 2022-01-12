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
  Nodes* = ref seq[seq[Node]]

proc parse*(node: TSNode, nodes: var Nodes) =
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
      nodes[][lineNum].add((kind, startCol, endCol))
  else:
    for i in 0 ..< ts_node_child_count(node):
      let child = ts_node_child(node, i)
      parse(child, nodes)

proc parse*(tree: pointer, lineCount: int): Nodes =
  if tree != nil:
    let node = ts_tree_root_node(tree)
    new(result)
    result[] = newSeq[seq[Node]](lineCount)
    parse(node, result)

proc editTree*(tree: pointer, parser: pointer, newLines: ref seq[string]): pointer =
  if parser != nil:
    let content = strutils.join(newLines[], "\n")
    result = ts_parser_parse_string(parser, nil, content, content.len.uint32)
  if tree != nil:
    ts_tree_delete(tree)
