// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_STREAM_COMPRESSOR_H)
#define ZSTDS_EXT_STREAM_COMPRESSOR_H

#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/common.h"

typedef struct {
  ZSTD_CCtx*          ctx;
  zstds_ext_symbol_t* destination_buffer;
  size_t              destination_buffer_length;
  zstds_ext_symbol_t* remaining_destination_buffer;
  size_t              remaining_destination_buffer_length;
} zstds_ext_compressor_t;

VALUE zstds_ext_allocate_compressor(VALUE klass);
VALUE zstds_ext_initialize_compressor(VALUE self, VALUE options);
VALUE zstds_ext_compress(VALUE self, VALUE source);
VALUE zstds_ext_flush_compressor(VALUE self);
VALUE zstds_ext_finish_compressor(VALUE self);
VALUE zstds_ext_compressor_read_result(VALUE self);
VALUE zstds_ext_compressor_close(VALUE self);

void zstds_ext_compressor_exports(VALUE root_module);

#endif // ZSTDS_EXT_STREAM_COMPRESSOR_H
