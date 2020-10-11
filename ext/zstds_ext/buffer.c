// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/buffer.h"

#include <zstd.h>

#include "ruby.h"

VALUE zstds_ext_create_string_buffer(VALUE length)
{
  return rb_str_new(NULL, NUM2SIZET(length));
}

VALUE zstds_ext_resize_string_buffer(VALUE args)
{
  VALUE buffer = rb_ary_entry(args, 0);
  VALUE length = rb_ary_entry(args, 1);

  return rb_str_resize(buffer, NUM2SIZET(length));
}

void zstds_ext_buffer_exports(VALUE root_module)
{
  VALUE module = rb_define_module_under(root_module, "Buffer");

  rb_define_const(module, "DEFAULT_SOURCE_BUFFER_LENGTH_FOR_COMPRESSOR", SIZET2NUM(ZSTD_CStreamInSize()));
  rb_define_const(module, "DEFAULT_DESTINATION_BUFFER_LENGTH_FOR_COMPRESSOR", SIZET2NUM(ZSTD_CStreamOutSize()));
  rb_define_const(module, "DEFAULT_SOURCE_BUFFER_LENGTH_FOR_DECOMPRESSOR", SIZET2NUM(ZSTD_DStreamInSize()));
  rb_define_const(module, "DEFAULT_DESTINATION_BUFFER_LENGTH_FOR_DECOMPRESSOR", SIZET2NUM(ZSTD_DStreamOutSize()));
}
