// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_OPTIONS_H)
#define ZSTDS_EXT_OPTIONS_H

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "ruby.h"
#include "zstds_ext/common.h"

// Default option values depends on zstd library.
// We will set only user defined values.

enum {
  ZSTDS_EXT_OPTION_TYPE_BOOL = 1,
  ZSTDS_EXT_OPTION_TYPE_FIXNUM,
  ZSTDS_EXT_OPTION_TYPE_STRATEGY
};

typedef uint_fast8_t zstds_ext_option_type_t;
typedef int          zstds_ext_option_value_t;

typedef struct {
  bool                     has_value;
  zstds_ext_option_value_t value;
} zstds_ext_option_t;

typedef struct {
  // zstds_ext_option_t disable_literal_context_modeling;
} zstds_ext_compressor_options_t;

typedef struct {
  // zstds_ext_option_t disable_ring_buffer_reallocation;
} zstds_ext_decompressor_options_t;

void zstds_ext_option_exports(VALUE root_module);

#endif // ZSTDS_EXT_OPTIONS_H
