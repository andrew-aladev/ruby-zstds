// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/stream/compressor.h"

#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/error.h"
#include "zstds_ext/option.h"

static void free_compressor(zstds_ext_compressor_t* compressor_ptr)
{
  ZSTD_CCtx* ctx = compressor_ptr->ctx;
  if (ctx != NULL) {
    ZSTD_freeCCtx(ctx);
  }

  zstds_ext_byte_t* destination_buffer = compressor_ptr->destination_buffer;
  if (destination_buffer != NULL) {
    free(destination_buffer);
  }

  free(compressor_ptr);
}

VALUE zstds_ext_allocate_compressor(VALUE klass)
{
  zstds_ext_compressor_t* compressor_ptr;
  VALUE                   self = Data_Make_Struct(klass, zstds_ext_compressor_t, NULL, free_compressor, compressor_ptr);

  compressor_ptr->ctx                                 = NULL;
  compressor_ptr->destination_buffer                  = NULL;
  compressor_ptr->destination_buffer_length           = 0;
  compressor_ptr->remaining_destination_buffer        = NULL;
  compressor_ptr->remaining_destination_buffer_length = 0;

  return self;
}

#define GET_COMPRESSOR(self)              \
  zstds_ext_compressor_t* compressor_ptr; \
  Data_Get_Struct(self, zstds_ext_compressor_t, compressor_ptr);

VALUE zstds_ext_initialize_compressor(VALUE self, VALUE options)
{
  GET_COMPRESSOR(self);
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

  if (destination_buffer_length == 0) {
    destination_buffer_length = ZSTD_CStreamOutSize();
  }

  zstds_ext_byte_t* destination_buffer = malloc(destination_buffer_length);
  if (destination_buffer == NULL) {
    ZSTD_freeCCtx(ctx);
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  compressor_ptr->ctx                                 = ctx;
  compressor_ptr->destination_buffer                  = destination_buffer;
  compressor_ptr->destination_buffer_length           = destination_buffer_length;
  compressor_ptr->remaining_destination_buffer        = destination_buffer;
  compressor_ptr->remaining_destination_buffer_length = destination_buffer_length;

  return Qnil;
}

#define DO_NOT_USE_AFTER_CLOSE(compressor_ptr)                                     \
  if (compressor_ptr->ctx == NULL || compressor_ptr->destination_buffer == NULL) { \
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_USED_AFTER_CLOSE);                       \
  }

#define GET_SOURCE_DATA(source_value)                    \
  Check_Type(source_value, T_STRING);                    \
                                                         \
  const char* source        = RSTRING_PTR(source_value); \
  size_t      source_length = RSTRING_LEN(source_value);

VALUE zstds_ext_compress(VALUE self, VALUE source_value)
{
  GET_COMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(compressor_ptr);
  GET_SOURCE_DATA(source_value);

  ZSTD_inBuffer in_buffer;
  in_buffer.src  = source;
  in_buffer.size = source_length;
  in_buffer.pos  = 0;

  ZSTD_outBuffer out_buffer;
  out_buffer.dst  = compressor_ptr->remaining_destination_buffer;
  out_buffer.size = compressor_ptr->remaining_destination_buffer_length;
  out_buffer.pos  = 0;

  zstds_result_t result = ZSTD_compressStream2(compressor_ptr->ctx, &out_buffer, &in_buffer, ZSTD_e_continue);
  if (ZSTD_isError(result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  compressor_ptr->remaining_destination_buffer += out_buffer.pos;
  compressor_ptr->remaining_destination_buffer_length -= out_buffer.pos;

  VALUE bytes_written          = SIZET2NUM(in_buffer.pos);
  VALUE needs_more_destination = compressor_ptr->remaining_destination_buffer_length == 0 ? Qtrue : Qfalse;

  return rb_ary_new_from_args(2, bytes_written, needs_more_destination);
}

VALUE zstds_ext_flush_compressor(VALUE self)
{
  GET_COMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(compressor_ptr);

  ZSTD_inBuffer in_buffer;
  in_buffer.src  = NULL;
  in_buffer.size = 0;
  in_buffer.pos  = 0;

  ZSTD_outBuffer out_buffer;
  out_buffer.dst  = compressor_ptr->remaining_destination_buffer;
  out_buffer.size = compressor_ptr->remaining_destination_buffer_length;
  out_buffer.pos  = 0;

  zstds_result_t result = ZSTD_compressStream2(compressor_ptr->ctx, &out_buffer, &in_buffer, ZSTD_e_flush);
  if (ZSTD_isError(result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  compressor_ptr->remaining_destination_buffer += out_buffer.pos;
  compressor_ptr->remaining_destination_buffer_length -= out_buffer.pos;

  return result != 0 ? Qtrue : Qfalse;
}

VALUE zstds_ext_finish_compressor(VALUE self)
{
  GET_COMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(compressor_ptr);

  ZSTD_inBuffer in_buffer;
  in_buffer.src  = NULL;
  in_buffer.size = 0;
  in_buffer.pos  = 0;

  ZSTD_outBuffer out_buffer;
  out_buffer.dst  = compressor_ptr->remaining_destination_buffer;
  out_buffer.size = compressor_ptr->remaining_destination_buffer_length;
  out_buffer.pos  = 0;

  zstds_result_t result = ZSTD_compressStream2(compressor_ptr->ctx, &out_buffer, &in_buffer, ZSTD_e_end);
  if (ZSTD_isError(result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  compressor_ptr->remaining_destination_buffer += out_buffer.pos;
  compressor_ptr->remaining_destination_buffer_length -= out_buffer.pos;

  return result != 0 ? Qtrue : Qfalse;
}

VALUE zstds_ext_compressor_read_result(VALUE self)
{
  GET_COMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(compressor_ptr);

  zstds_ext_byte_t* destination_buffer                  = compressor_ptr->destination_buffer;
  size_t            destination_buffer_length           = compressor_ptr->destination_buffer_length;
  size_t            remaining_destination_buffer_length = compressor_ptr->remaining_destination_buffer_length;

  const char* result        = (const char*) destination_buffer;
  size_t      result_length = destination_buffer_length - remaining_destination_buffer_length;
  VALUE       result_value  = rb_str_new(result, result_length);

  compressor_ptr->remaining_destination_buffer        = destination_buffer;
  compressor_ptr->remaining_destination_buffer_length = destination_buffer_length;

  return result_value;
}

VALUE zstds_ext_compressor_close(VALUE self)
{
  GET_COMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(compressor_ptr);

  ZSTD_CCtx* ctx = compressor_ptr->ctx;
  if (ctx != NULL) {
    ZSTD_freeCCtx(ctx);

    compressor_ptr->ctx = NULL;
  }

  zstds_ext_byte_t* destination_buffer = compressor_ptr->destination_buffer;
  if (destination_buffer != NULL) {
    free(destination_buffer);

    compressor_ptr->destination_buffer = NULL;
  }

  // It is possible to keep "destination_buffer_length", "remaining_destination_buffer"
  //   and "remaining_destination_buffer_length" as is.

  return Qnil;
}

void zstds_ext_compressor_exports(VALUE root_module)
{
  VALUE module = rb_define_module_under(root_module, "Stream");

  VALUE compressor = rb_define_class_under(module, "NativeCompressor", rb_cObject);

  rb_define_alloc_func(compressor, zstds_ext_allocate_compressor);
  rb_define_method(compressor, "initialize", zstds_ext_initialize_compressor, 1);
  rb_define_method(compressor, "write", zstds_ext_compress, 1);
  rb_define_method(compressor, "flush", zstds_ext_flush_compressor, 0);
  rb_define_method(compressor, "finish", zstds_ext_finish_compressor, 0);
  rb_define_method(compressor, "read_result", zstds_ext_compressor_read_result, 0);
  rb_define_method(compressor, "close", zstds_ext_compressor_close, 0);
}
