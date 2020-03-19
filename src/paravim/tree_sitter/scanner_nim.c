#include "tree_sitter/parser.h"

void *tree_sitter_python_external_scanner_create(void);
void tree_sitter_python_external_scanner_destroy(void *);
bool tree_sitter_python_external_scanner_scan(void *, TSLexer *, const bool *);
unsigned tree_sitter_python_external_scanner_serialize(void *, char *);
void tree_sitter_python_external_scanner_deserialize(void *, const char *, unsigned);

void *tree_sitter_nim_external_scanner_create() {
  return tree_sitter_python_external_scanner_create();
}

bool tree_sitter_nim_external_scanner_scan(void *payload, TSLexer *lexer,
                                            const bool *valid_symbols) {
  return tree_sitter_python_external_scanner_scan(payload, lexer, valid_symbols);
}

unsigned tree_sitter_nim_external_scanner_serialize(void *payload, char *buffer) {
  return tree_sitter_python_external_scanner_serialize(payload, buffer);
}

void tree_sitter_nim_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  tree_sitter_python_external_scanner_deserialize(payload, buffer, length);
}

void tree_sitter_nim_external_scanner_destroy(void *payload) {
  tree_sitter_python_external_scanner_destroy(payload);
}
