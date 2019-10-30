// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_STRING_H)
#define ZSTDS_EXT_STRING_H

#include "ruby.h"

VALUE zstds_ext_compress_string(VALUE self, VALUE source, VALUE options);
VALUE zstds_ext_decompress_string(VALUE self, VALUE source, VALUE options);

void zstds_ext_string_exports(VALUE root_module);

#endif // ZSTDS_EXT_STRING_H
