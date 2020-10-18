// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_BUFFER_H)
#define ZSTDS_EXT_BUFFER_H

#include "ruby.h"

VALUE zstds_ext_create_string_buffer(VALUE length);

#define ZSTDS_EXT_CREATE_STRING_BUFFER(buffer, length, exception) \
  VALUE buffer = rb_protect(zstds_ext_create_string_buffer, SIZET2NUM(length), &exception);

VALUE zstds_ext_resize_string_buffer(VALUE buffer_args);

#define ZSTDS_EXT_RESIZE_STRING_BUFFER(buffer, length, exception)                          \
  VALUE buffer_args = rb_ary_new_from_args(2, buffer, SIZET2NUM(length));                  \
  buffer            = rb_protect(zstds_ext_resize_string_buffer, buffer_args, &exception); \
  RB_GC_GUARD(buffer_args);

void zstds_ext_buffer_exports(VALUE root_module);

#endif // ZSTDS_EXT_BUFFER_H
