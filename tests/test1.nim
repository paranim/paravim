# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
from paravim/tree_sitter import nil

test "parse nim file with tree sitter":
  let
    lines = @["echo \"Hello, world!\""]
    (tree, parser) = tree_sitter.init("stuff.nim", lines)
    parsed = tree_sitter.parse(tree, lines.len)
