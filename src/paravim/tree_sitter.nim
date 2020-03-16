{.compile: "tree_sitter/lib.c".}
{.compile: "tree_sitter/parser_javascript.c".}
{.compile: "tree_sitter/parser_javascript_scanner.c".}

import tree_sitter/tree_sitter/api
from os import nil
from strutils import nil
import tables

proc free(p: pointer) {.cdecl, importc: "free".}
proc tree_sitter_javascript(): pointer {.cdecl, importc: "tree_sitter_javascript".}

proc createTree*(path: string, lines: seq[string]): pointer =
  let parser = ts_parser_new()
  let (_, _, ext) = os.splitFile(path)
  case ext:
    of ".js":
      doAssert ts_parser_set_language(parser, tree_sitter_javascript())
    else:
      ts_parser_delete(parser)
      return nil
  let content = strutils.join(lines, "\n")
  ts_parser_parse_string(parser, nil, content, content.len.uint32)

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
  Node* = tuple[kind: string, startCol: int, endCol: int]

proc parse*(node: TSNode, nodes: var Table[int, seq[Node]]) =
  let kind = $ ts_node_type(node)
  case kind:
    of "string", "template_string":
      let
        startPoint = ts_node_start_point(node)
        childCount = ts_node_child_count(node)
      var endPoint = ts_node_end_point(node)
      if childCount > 0.uint32:
        let child = ts_node_child(node, childCount - 1)
        endPoint = ts_node_end_point(child)
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
