// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/string.h"

#include <zstd.h>

#include "zstds_ext/buffer.h"
#include "zstds_ext/error.h"
#include "zstds_ext/gvl.h"
#include "zstds_ext/macro.h"
#include "zstds_ext/option.h"

// -- buffer --

static inline zstds_ext_result_t increase_destination_buffer(
  VALUE   destination_value,
  size_t  destination_length,
  size_t* remaining_destination_buffer_length_ptr,
  size_t  destination_buffer_length)
{
  if (*remaining_destination_buffer_length_ptr == destination_buffer_length) {
    // We want to write more data at once, than buffer has.
    return ZSTDS_EXT_ERROR_NOT_ENOUGH_DESTINATION_BUFFER;
  }

  int exception;

  ZSTDS_EXT_RESIZE_STRING_BUFFER(destination_value, destination_length + destination_buffer_length, exception);
  if (exception != 0) {
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  *remaining_destination_buffer_length_ptr = destination_buffer_length;

  return 0;
}

// -- compress --

typedef struct
{
  ZSTD_CCtx*      ctx;
  ZSTD_inBuffer*  in_buffer_ptr;
  ZSTD_outBuffer* out_buffer_ptr;
  zstds_result_t  result;
} compress_args_t;

static inline void* compress_wrapper(void* data)
{
  compress_args_t* args = data;

  args->result = ZSTD_compressStream2(args->ctx, args->out_buffer_ptr, args->in_buffer_ptr, ZSTD_e_end);

  return NULL;
}

static inline zstds_ext_result_t compress(
  ZSTD_CCtx*  ctx,
  const char* source,
  size_t      source_length,
  VALUE       destination_value,
  size_t      destination_buffer_length,
  bool        gvl)
{
  zstds_ext_result_t ext_result;
  size_t             destination_length                  = 0;
  size_t             remaining_destination_buffer_length = destination_buffer_length;
  ZSTD_inBuffer      in_buffer                           = {.src = source, .size = source_length, .pos = 0};
  compress_args_t    args                                = {.ctx = ctx, .in_buffer_ptr = &in_buffer};

  while (true) {
    ZSTD_outBuffer out_buffer = {
      .dst  = (zstds_ext_byte_t*) RSTRING_PTR(destination_value) + destination_length,
      .size = remaining_destination_buffer_length,
      .pos  = 0};

    args.out_buffer_ptr = &out_buffer;

    ZSTDS_EXT_GVL_WRAP(gvl, compress_wrapper, &args);
    if (ZSTD_isError(args.result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(args.result));
    }

    destination_length += out_buffer.pos;
    remaining_destination_buffer_length -= out_buffer.pos;

    if (args.result != 0) {
      ext_result = increase_destination_buffer(
        destination_value, destination_length, &remaining_destination_buffer_length, destination_buffer_length);

      if (ext_result != 0) {
        return ext_result;
      }

      continue;
    }

    break;
  }

  int exception;

  ZSTDS_EXT_RESIZE_STRING_BUFFER(destination_value, destination_length, exception);
  if (exception != 0) {
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  return 0;
}

VALUE zstds_ext_compress_string(VALUE ZSTDS_EXT_UNUSED(self), VALUE source_value, VALUE options)
{
  Check_Type(source_value, T_STRING);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_SIZE_OPTION(options, destination_buffer_length);
  ZSTDS_EXT_GET_BOOL_OPTION(options, gvl);
  ZSTDS_EXT_GET_COMPRESSOR_OPTIONS(options);

  ZSTD_CCtx* ctx = ZSTD_createCCtx();
  if (ctx == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  zstds_ext_result_t ext_result = zstds_ext_set_compressor_options(ctx, &compressor_options);
  if (ext_result != 0) {
    ZSTD_freeCCtx(ctx);
    zstds_ext_raise_error(ext_result);
  }

  if (destination_buffer_length == 0) {
    destination_buffer_length = ZSTD_CStreamOutSize();
  }

  int exception;

  ZSTDS_EXT_CREATE_STRING_BUFFER(destination_value, destination_buffer_length, exception);
  if (exception != 0) {
    ZSTD_freeCCtx(ctx);
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  const char* source        = RSTRING_PTR(source_value);
  size_t      source_length = RSTRING_LEN(source_value);

  ext_result = compress(ctx, source, source_length, destination_value, destination_buffer_length, gvl);

  ZSTD_freeCCtx(ctx);

  if (ext_result != 0) {
    zstds_ext_raise_error(ext_result);
  }

  return destination_value;
}

// -- decompress --

typedef struct
{
  ZSTD_DCtx*      ctx;
  ZSTD_inBuffer*  in_buffer_ptr;
  ZSTD_outBuffer* out_buffer_ptr;
  zstds_result_t  result;
} decompress_args_t;

static inline void* decompress_wrapper(void* data)
{
  decompress_args_t* args = data;

  args->result = ZSTD_decompressStream(args->ctx, args->out_buffer_ptr, args->in_buffer_ptr);

  return NULL;
}

static inline zstds_ext_result_t decompress(
  ZSTD_DCtx*  ctx,
  const char* source,
  size_t      source_length,
  VALUE       destination_value,
  size_t      destination_buffer_length,
  bool        gvl)
{
  zstds_ext_result_t ext_result;
  size_t             destination_length                  = 0;
  size_t             remaining_destination_buffer_length = destination_buffer_length;
  ZSTD_inBuffer      in_buffer                           = {.src = source, .size = source_length, .pos = 0};
  decompress_args_t  args                                = {.ctx = ctx, .in_buffer_ptr = &in_buffer};

  while (true) {
    ZSTD_outBuffer out_buffer = {
      .dst  = (zstds_ext_byte_t*) RSTRING_PTR(destination_value) + destination_length,
      .size = remaining_destination_buffer_length,
      .pos  = 0};

    args.out_buffer_ptr = &out_buffer;

    ZSTDS_EXT_GVL_WRAP(gvl, decompress_wrapper, &args);
    if (ZSTD_isError(args.result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(args.result));
    }

    destination_length += out_buffer.pos;
    remaining_destination_buffer_length -= out_buffer.pos;

    if (remaining_destination_buffer_length == 0) {
      ext_result = increase_destination_buffer(
        destination_value, destination_length, &remaining_destination_buffer_length, destination_buffer_length);

      if (ext_result != 0) {
        return ext_result;
      }

      continue;
    }

    break;
  }

  int exception;

  ZSTDS_EXT_RESIZE_STRING_BUFFER(destination_value, destination_length, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  return 0;
}

VALUE zstds_ext_decompress_string(VALUE ZSTDS_EXT_UNUSED(self), VALUE source_value, VALUE options)
{
  Check_Type(source_value, T_STRING);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_SIZE_OPTION(options, destination_buffer_length);
  ZSTDS_EXT_GET_BOOL_OPTION(options, gvl);
  ZSTDS_EXT_GET_DECOMPRESSOR_OPTIONS(options);

  ZSTD_DCtx* ctx = ZSTD_createDCtx();
  if (ctx == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  zstds_ext_result_t ext_result = zstds_ext_set_decompressor_options(ctx, &decompressor_options);
  if (ext_result != 0) {
    ZSTD_freeDCtx(ctx);
    zstds_ext_raise_error(ext_result);
  }

  if (destination_buffer_length == 0) {
    destination_buffer_length = ZSTD_DStreamOutSize();
  }

  int exception;

  ZSTDS_EXT_CREATE_STRING_BUFFER(destination_value, destination_buffer_length, exception);
  if (exception != 0) {
    ZSTD_freeDCtx(ctx);
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  const char* source        = RSTRING_PTR(source_value);
  size_t      source_length = RSTRING_LEN(source_value);

  ext_result = decompress(ctx, source, source_length, destination_value, destination_buffer_length, gvl);

  ZSTD_freeDCtx(ctx);

  if (ext_result != 0) {
    zstds_ext_raise_error(ext_result);
  }

  return destination_value;
}

// -- exports --

void zstds_ext_string_exports(VALUE root_module)
{
  rb_define_module_function(root_module, "_native_compress_string", RUBY_METHOD_FUNC(zstds_ext_compress_string), 2);
  rb_define_module_function(root_module, "_native_decompress_string", RUBY_METHOD_FUNC(zstds_ext_decompress_string), 2);
}
