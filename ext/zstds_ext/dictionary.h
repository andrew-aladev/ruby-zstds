// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_DICTIONARY_H)
#define ZSTDS_EXT_DICTIONARY_H

#include <stdint.h>
#include <stdlib.h>

#include "ruby.h"

typedef struct {
  uint8_t* buffer;
  size_t   size;
} zstds_ext_dictionary_t;

#define ZSTDS_EXT_DEFAULT_DICTIONARY_CAPACITY (1 << 17); // 128 KB

VALUE zstds_ext_allocate_dictionary(VALUE klass);
VALUE zstds_ext_initialize_dictionary(VALUE self, VALUE samples, VALUE options);
VALUE zstds_ext_get_dictionary_size(VALUE self);
VALUE zstds_ext_get_dictionary_id(VALUE self);

void zstds_ext_dictionary_exports(VALUE root_module);

#endif // ZSTDS_EXT_DICTIONARY_H
