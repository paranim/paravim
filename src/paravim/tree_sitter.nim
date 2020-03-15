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
