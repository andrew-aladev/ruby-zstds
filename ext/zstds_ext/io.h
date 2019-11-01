// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_IO_H)
#define ZSTDS_EXT_IO_H

#include "ruby.h"

VALUE zstds_ext_compress_io(VALUE self, VALUE source, VALUE destination, VALUE options);
VALUE zstds_ext_decompress_io(VALUE self, VALUE source, VALUE destination, VALUE options);

void zstds_ext_io_exports(VALUE root_module);

#endif // ZSTDS_EXT_IO_H
