// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_STREAM_DECOMPRESSOR_H)
#define ZSTDS_EXT_STREAM_DECOMPRESSOR_H

#include <stdbool.h>
#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/common.h"

typedef struct
{
  ZSTD_DCtx*        ctx;
  zstds_ext_byte_t* destination_buffer;
  size_t            destination_buffer_length;
  zstds_ext_byte_t* remaining_destination_buffer;
  size_t            remaining_destination_buffer_length;
  bool              gvl;
} zstds_ext_decompressor_t;

VALUE zstds_ext_allocate_decompressor(VALUE klass);
VALUE zstds_ext_initialize_decompressor(VALUE self, VALUE options);
VALUE zstds_ext_decompress(VALUE self, VALUE source);
VALUE zstds_ext_decompressor_read_result(VALUE self);
VALUE zstds_ext_decompressor_close(VALUE self);

void zstds_ext_decompressor_exports(VALUE root_module);

#endif // ZSTDS_EXT_STREAM_DECOMPRESSOR_H
