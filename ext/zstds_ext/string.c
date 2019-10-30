// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/string.h"

#include <stdint.h>
#include <stdlib.h>
#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/buffer.h"
#include "zstds_ext/common.h"
#include "zstds_ext/error.h"
#include "zstds_ext/macro.h"
#include "zstds_ext/option.h"

// -- buffer --

static inline VALUE create_buffer(VALUE length)
{
  return rb_str_new(NULL, NUM2SIZET(length));
}

#define CREATE_BUFFER(buffer, length, exception) \
  VALUE buffer = rb_protect(create_buffer, SIZET2NUM(length), &exception);

static inline VALUE resize_buffer(VALUE args)
{
  VALUE buffer = rb_ary_entry(args, 0);
  VALUE length = rb_ary_entry(args, 1);
  return rb_str_resize(buffer, NUM2SIZET(length));
}

#define RESIZE_BUFFER(buffer, length, exception)                                        \
  VALUE resize_buffer_args = rb_ary_new_from_args(2, buffer, SIZET2NUM(length));        \
  buffer                   = rb_protect(resize_buffer, resize_buffer_args, &exception); \
  RB_GC_GUARD(resize_buffer_args);

static inline zstds_ext_result_t increase_destination_buffer(
  VALUE destination_value, size_t destination_length,
  size_t* remaining_destination_buffer_length_ptr, size_t destination_buffer_length)
{
  if (*remaining_destination_buffer_length_ptr == destination_buffer_length) {
    // We want to write more data at once, than buffer has.
    return ZSTDS_EXT_ERROR_NOT_ENOUGH_DESTINATION_BUFFER;
  }

  int exception;

  RESIZE_BUFFER(destination_value, destination_length + destination_buffer_length, exception);
  if (exception != 0) {
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  *remaining_destination_buffer_length_ptr = destination_buffer_length;

  return 0;
}

// -- utils --

#define GET_SOURCE_DATA(source_value)                                 \
  Check_Type(source_value, T_STRING);                                 \
                                                                      \
  const char*    source                  = RSTRING_PTR(source_value); \
  size_t         source_length           = RSTRING_LEN(source_value); \
  const uint8_t* remaining_source        = (const uint8_t*)source;    \
  size_t         remaining_source_length = source_length;

// -- compress --

VALUE zstds_ext_compress_string(VALUE ZSTDS_EXT_UNUSED(self), VALUE source_value, VALUE options)
{
  GET_SOURCE_DATA(source_value);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_COMPRESSOR_OPTIONS(options);
  ZSTDS_EXT_GET_BUFFER_LENGTH_OPTION(options, destination_buffer_length);

  ZSTD_CCtx* ctx = ZSTD_createCCtx();
  if (ctx == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  zstds_ext_result_t ext_result = zstds_ext_set_compressor_options(ctx, &compressor_options);
  if (ext_result != 0) {
    ZSTD_freeCCtx(ctx);
    zstds_ext_raise_error(ext_result);
  }

  // if (destination_buffer_length == 0) {
  //   destination_buffer_length = BRS_DEFAULT_DESTINATION_BUFFER_LENGTH_FOR_COMPRESSOR;
  // }
  //
  // int exception;
  //
  // CREATE_BUFFER(destination_value, destination_buffer_length, exception);
  // if (exception != 0) {
  //   BrotliEncoderDestroyInstance(state_ptr);
  //   brs_ext_raise_error(BRS_EXT_ERROR_ALLOCATE_FAILED);
  // }
  //
  // ext_result = compress(
  //   state_ptr,
  //   remaining_source, remaining_source_length,
  //   destination_value, destination_buffer_length);
  //
  // BrotliEncoderDestroyInstance(state_ptr);
  //
  // if (ext_result != 0) {
  //   brs_ext_raise_error(ext_result);
  // }
  //
  // return destination_value;

  return Qnil;
}

// -- decompress --

VALUE zstds_ext_decompress_string(VALUE ZSTDS_EXT_UNUSED(self), VALUE source_value, VALUE options)
{
  GET_SOURCE_DATA(source_value);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_DECOMPRESSOR_OPTIONS(options);
  ZSTDS_EXT_GET_BUFFER_LENGTH_OPTION(options, destination_buffer_length);

  ZSTD_DCtx* ctx = ZSTD_createDCtx();
  if (ctx == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  zstds_ext_result_t ext_result = zstds_ext_set_decompressor_options(ctx, &decompressor_options);
  if (ext_result != 0) {
    ZSTD_freeDCtx(ctx);
    zstds_ext_raise_error(ext_result);
  }

  // if (destination_buffer_length == 0) {
  //   destination_buffer_length = BRS_DEFAULT_DESTINATION_BUFFER_LENGTH_FOR_DECOMPRESSOR;
  // }
  //
  // int exception;
  //
  // CREATE_BUFFER(destination_value, destination_buffer_length, exception);
  // if (exception != 0) {
  //   BrotliDecoderDestroyInstance(state_ptr);
  //   brs_ext_raise_error(BRS_EXT_ERROR_ALLOCATE_FAILED);
  // }
  //
  // ext_result = decompress(
  //   state_ptr,
  //   remaining_source, remaining_source_length,
  //   destination_value, destination_buffer_length);
  //
  // BrotliDecoderDestroyInstance(state_ptr);
  //
  // if (ext_result != 0) {
  //   brs_ext_raise_error(ext_result);
  // }
  //
  // return destination_value;

  return Qnil;
}

void zstds_ext_string_exports(VALUE root_module)
{
  rb_define_module_function(root_module, "_native_compress_string", RUBY_METHOD_FUNC(zstds_ext_compress_string), 2);
  rb_define_module_function(root_module, "_native_decompress_string", RUBY_METHOD_FUNC(zstds_ext_decompress_string), 2);
}
