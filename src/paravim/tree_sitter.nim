{.compile: "tree_sitter/lib.c".}
{.compile: "tree_sitter/parser_javascript.c".}
{.compile: "tree_sitter/parser_javascript_scanner.c".}

import tree_sitter/tree_sitter/api
from os import nil
from strutils import nil

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
  RangeTuple = tuple[startLine: uint32, startColumn: uint32, endLine: uint32, endColumn: uint32]

proc parse*(node: TSNode, nodes: var seq[tuple[kind: string, location: RangeTuple]]) =
  let
    kind = $ ts_node_type(node)
  case kind:
    of "string":
      let
        startPoint = ts_node_start_point(node)
        childCount = ts_node_child_count(node)
      var endPoint = ts_node_end_point(node)
      if childCount > 0.uint32:
        let child = ts_node_child(node, childCount - 1)
        endPoint = ts_node_end_point(child)
      nodes.add((kind: kind, location: (startPoint.row, startPoint.column, endPoint.row, endPoint.column)))
    else:
      for i in 0 ..< ts_node_child_count(node):
        let child = ts_node_child(node, i)
        parse(child, nodes)

proc parse*(tree: pointer): seq[tuple[kind: string, location: RangeTuple]] =
  if tree != nil:
    let node = ts_tree_root_node(tree)
    parse(node, result)
