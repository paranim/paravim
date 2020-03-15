{.compile: "tree_sitter/lib.c".}
{.compile: "tree_sitter/parser_javascript.c".}
{.compile: "tree_sitter/parser_javascript_scanner.c".}

import tree_sitter/tree_sitter/api

proc tree_sitter_javascript*(): pointer {.cdecl, importc: "tree_sitter_javascript".}

let parser = ts_parser_new()
echo ts_parser_set_language(parser, tree_sitter_javascript())
