#include "tree_sitter/parser.h"
#include <wctype.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#define STB_DS_IMPLEMENTATION
#include "stb_ds.h"

struct Scanner {
  uint16_t *indent_length_stack;
  char *delimiter_stack;
};

enum TokenType {
  NEWLINE,
  INDENT,
  DEDENT,
  STRING_START,
  STRING_CONTENT,
  STRING_END,
};

enum {
  SingleQuote = 1 << 0,
  DoubleQuote = 1 << 1,
  BackQuote = 1 << 2,
  Raw = 1 << 3,
  Format = 1 << 4,
  Triple = 1 << 5,
  Bytes = 1 << 6,
};

bool is_format(char *flags) {
  return *flags & Format;
}

bool is_raw(char *flags) {
  return *flags & Raw;
}

bool is_triple(char *flags) {
  return *flags & Triple;
}

bool is_bytes(char *flags) {
  return *flags & Bytes;
}

int32_t end_character(char *flags) {
  if (*flags & SingleQuote) return '\'';
  if (*flags & DoubleQuote) return '"';
  if (*flags & BackQuote) return '`';
  return 0;
}

void set_format(char *flags) {
  *flags |= Format;
}

void set_raw(char *flags) {
  *flags |= Raw;
}

void set_triple(char *flags) {
  *flags |= Triple;
}

void set_bytes(char *flags) {
  *flags |= Bytes;
}

void set_end_character(char *flags, int32_t character) {
  switch (character) {
    case '\'':
      *flags |= SingleQuote;
      break;
    case '"':
      *flags |= DoubleQuote;
      break;
    case '`':
      *flags |= BackQuote;
      break;
    default:
      assert(false);
  }
}

void advance(TSLexer *lexer) {
  lexer->advance(lexer, false);
}

void skip(TSLexer *lexer) {
  lexer->advance(lexer, true);
}

bool scan(struct Scanner *scanner, TSLexer *lexer, const bool *valid_symbols) {
  if (valid_symbols[STRING_CONTENT] && !valid_symbols[INDENT] && arrlen(scanner->delimiter_stack) != 0) {
    char delimiter = arrlast(scanner->delimiter_stack);
    int32_t end_char = end_character(&delimiter);
    bool has_content = false;
    while (lexer->lookahead) {
      if (lexer->lookahead == '{' && is_format(&delimiter)) {
        lexer->mark_end(lexer);
        lexer->advance(lexer, false);
        if (lexer->lookahead == '{') {
          lexer->advance(lexer, false);
        } else {
          lexer->result_symbol = STRING_CONTENT;
          return has_content;
        }
      } else if (lexer->lookahead == '\\') {
        if (is_raw(&delimiter)) {
          lexer->advance(lexer, false);
        } else if (is_bytes(&delimiter)) {
            lexer->mark_end(lexer);
            lexer->advance(lexer, false);
            if (lexer->lookahead == 'N' || lexer->lookahead == 'u' || lexer->lookahead == 'U') {
              // In bytes string, \N{...}, \uXXXX and \UXXXXXXXX are not escape sequences
              // https://docs.python.org/3/reference/lexical_analysis.html#string-and-bytes-literals
              lexer->advance(lexer, false);
            } else {
                lexer->result_symbol = STRING_CONTENT;
                return has_content;
            }
        } else {
          lexer->mark_end(lexer);
          lexer->result_symbol = STRING_CONTENT;
          return has_content;
        }
      } else if (lexer->lookahead == end_char) {
        if (is_triple(&delimiter)) {
          lexer->mark_end(lexer);
          lexer->advance(lexer, false);
          if (lexer->lookahead == end_char) {
            lexer->advance(lexer, false);
            if (lexer->lookahead == end_char) {
              if (has_content) {
                lexer->result_symbol = STRING_CONTENT;
              } else {
                lexer->advance(lexer, false);
                lexer->mark_end(lexer);
                arrpop(scanner->delimiter_stack);
                lexer->result_symbol = STRING_END;
              }
              return true;
            }
          }
        } else {
          if (has_content) {
            lexer->result_symbol = STRING_CONTENT;
          } else {
            lexer->advance(lexer, false);
            arrpop(scanner->delimiter_stack);
            lexer->result_symbol = STRING_END;
          }
          lexer->mark_end(lexer);
          return true;
        }
      } else if (lexer->lookahead == '\n' && has_content && !is_triple(&delimiter)) {
        return false;
      }
      advance(lexer);
      has_content = true;
    }
  }

  lexer->mark_end(lexer);

  bool has_comment = false;
  bool has_newline = false;
  uint32_t indent_length = 0;
  for (;;) {
    if (lexer->lookahead == '\n') {
      has_newline = true;
      indent_length = 0;
      skip(lexer);
    } else if (lexer->lookahead == ' ') {
      indent_length++;
      skip(lexer);
    } else if (lexer->lookahead == '\r') {
      indent_length = 0;
      skip(lexer);
    } else if (lexer->lookahead == '\t') {
      indent_length += 8;
      skip(lexer);
    } else if (lexer->lookahead == '#') {
      has_comment = true;
      while (lexer->lookahead && lexer->lookahead != '\n') skip(lexer);
      skip(lexer);
      indent_length = 0;
    } else if (lexer->lookahead == '\\') {
      skip(lexer);
      if (iswspace(lexer->lookahead)) {
        skip(lexer);
      } else {
        return false;
      }
    } else if (lexer->lookahead == '\f') {
      indent_length = 0;
      skip(lexer);
    } else if (lexer->lookahead == 0) {
      if (valid_symbols[DEDENT] && arrlen(scanner->indent_length_stack) > 1) {
        arrpop(scanner->indent_length_stack);
        lexer->result_symbol = DEDENT;
        return true;
      }

      if (valid_symbols[NEWLINE]) {
        lexer->result_symbol = NEWLINE;
        return true;
      }

      break;
    } else {
      break;
    }
  }

  if (has_newline) {
    if (indent_length > arrlast(scanner->indent_length_stack) && valid_symbols[INDENT]) {
      arrput(scanner->indent_length_stack, indent_length);
      lexer->result_symbol = INDENT;
      return true;
    }

    if (indent_length < arrlast(scanner->indent_length_stack) && valid_symbols[DEDENT]) {
      arrpop(scanner->indent_length_stack);
      lexer->result_symbol = DEDENT;
      return true;
    }

    if (valid_symbols[NEWLINE]) {
      lexer->result_symbol = NEWLINE;
      return true;
    }
  }

  if (!has_comment && valid_symbols[STRING_START]) {
    char delimiter = 0;

    bool has_flags = false;
    while (lexer->lookahead) {
      if (lexer->lookahead == 'f' || lexer->lookahead == 'F') {
        set_format(&delimiter);
      } else if (lexer->lookahead == 'r' || lexer->lookahead == 'R') {
        set_raw(&delimiter);
      } else if (lexer->lookahead == 'b' || lexer->lookahead == 'B') {
        set_bytes(&delimiter);
      } else if (lexer->lookahead != 'u' && lexer->lookahead != 'U') {
        break;
      }
      has_flags = true;
      advance(lexer);
    }

    if (lexer->lookahead == '`') {
      set_end_character(&delimiter, '`');
      advance(lexer);
      lexer->mark_end(lexer);
    } else if (lexer->lookahead == '\'') {
      set_end_character(&delimiter, '\'');
      advance(lexer);
      lexer->mark_end(lexer);
      if (lexer->lookahead == '\'') {
        advance(lexer);
        if (lexer->lookahead == '\'') {
          advance(lexer);
          lexer->mark_end(lexer);
          set_triple(&delimiter);
        }
      }
    } else if (lexer->lookahead == '"') {
      set_end_character(&delimiter, '"');
      advance(lexer);
      lexer->mark_end(lexer);
      if (lexer->lookahead == '"') {
        advance(lexer);
        if (lexer->lookahead == '"') {
          advance(lexer);
          lexer->mark_end(lexer);
          set_triple(&delimiter);
        }
      }
    }

    if (end_character(&delimiter)) {
      arrput(scanner->delimiter_stack, delimiter);
      lexer->result_symbol = STRING_START;
      return true;
    } else if (has_flags) {
      return false;
    }
  }

  return false;
}

unsigned serialize(struct Scanner *scanner, char *buffer) {
  size_t i = 0;

  size_t stack_size = arrlen(scanner->delimiter_stack);
  if (stack_size > UINT8_MAX) stack_size = UINT8_MAX;
  buffer[i++] = stack_size;

  memcpy(&buffer[i], scanner->delimiter_stack, stack_size);
  i += stack_size;

  for (int iter = 1; iter != arrlen(scanner->indent_length_stack) && i < TREE_SITTER_SERIALIZATION_BUFFER_SIZE; ++iter) {
    buffer[i++] = scanner->indent_length_stack[iter];
  }

  return i;
}

void deserialize(struct Scanner *scanner, const char *buffer, unsigned length) {
  arrfree(scanner->delimiter_stack);
  arrfree(scanner->indent_length_stack);
  arrput(scanner->indent_length_stack, 0);

  if (length > 0) {
    size_t i = 0;

    size_t delimiter_count = (uint8_t)buffer[i++];
    arrsetlen(scanner->delimiter_stack, delimiter_count);
    memcpy(scanner->delimiter_stack, &buffer[i], delimiter_count);
    i += delimiter_count;

    for (; i < length; i++) {
      arrput(scanner->indent_length_stack, buffer[i]);
    }
  }
}

void init_scanner(struct Scanner *scanner) {
  deserialize(scanner, NULL, 0);
}

void *tree_sitter_python_external_scanner_create() {
  void *scanner = calloc(1, sizeof(struct Scanner));
  init_scanner((struct Scanner*) scanner);
  return scanner;
}

bool tree_sitter_python_external_scanner_scan(void *payload, TSLexer *lexer,
                                            const bool *valid_symbols) {
  return scan((struct Scanner*) payload, lexer, valid_symbols);
}

unsigned tree_sitter_python_external_scanner_serialize(void *payload, char *buffer) {
  return serialize((struct Scanner*) payload, buffer);
}

void tree_sitter_python_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  deserialize((struct Scanner*) payload, buffer, length);
}

void tree_sitter_python_external_scanner_destroy(void *payload) {
  struct Scanner *scanner = (struct Scanner*) payload;
  arrfree(scanner->indent_length_stack);
  arrfree(scanner->delimiter_stack);
  free(scanner);
}
