// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/stream/decompressor.h"

#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/error.h"
#include "zstds_ext/gvl.h"
#include "zstds_ext/option.h"

// -- initialization --

static void free_decompressor(zstds_ext_decompressor_t* decompressor_ptr)
{
  ZSTD_DCtx* ctx = decompressor_ptr->ctx;
  if (ctx != NULL) {
    ZSTD_freeDCtx(ctx);
  }

  zstds_ext_byte_t* destination_buffer = decompressor_ptr->destination_buffer;
  if (destination_buffer != NULL) {
    free(destination_buffer);
  }

  free(decompressor_ptr);
}

VALUE zstds_ext_allocate_decompressor(VALUE klass)
{
  zstds_ext_decompressor_t* decompressor_ptr;
  VALUE self = Data_Make_Struct(klass, zstds_ext_decompressor_t, NULL, free_decompressor, decompressor_ptr);

  decompressor_ptr->ctx                                 = NULL;
  decompressor_ptr->destination_buffer                  = NULL;
  decompressor_ptr->destination_buffer_length           = 0;
  decompressor_ptr->remaining_destination_buffer        = NULL;
  decompressor_ptr->remaining_destination_buffer_length = 0;

  return self;
}

#define GET_DECOMPRESSOR(self)                \
  zstds_ext_decompressor_t* decompressor_ptr; \
  Data_Get_Struct(self, zstds_ext_decompressor_t, decompressor_ptr);

VALUE zstds_ext_initialize_decompressor(VALUE self, VALUE options)
{
  GET_DECOMPRESSOR(self);
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

  zstds_ext_byte_t* destination_buffer = malloc(destination_buffer_length);
  if (destination_buffer == NULL) {
    ZSTD_freeDCtx(ctx);
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  decompressor_ptr->ctx                                 = ctx;
  decompressor_ptr->destination_buffer                  = destination_buffer;
  decompressor_ptr->destination_buffer_length           = destination_buffer_length;
  decompressor_ptr->remaining_destination_buffer        = destination_buffer;
  decompressor_ptr->remaining_destination_buffer_length = destination_buffer_length;
  decompressor_ptr->gvl                                 = gvl;

  return Qnil;
}

// -- decompress --

#define DO_NOT_USE_AFTER_CLOSE(decompressor_ptr)                                       \
  if (decompressor_ptr->ctx == NULL || decompressor_ptr->destination_buffer == NULL) { \
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_USED_AFTER_CLOSE);                           \
  }

typedef struct
{
  zstds_ext_decompressor_t* decompressor_ptr;
  ZSTD_inBuffer*            in_buffer_ptr;
  ZSTD_outBuffer*           out_buffer_ptr;
  zstds_result_t            result;
} decompress_args_t;

static inline void* decompress_wrapper(void* data)
{
  decompress_args_t* args = data;

  args->result = ZSTD_decompressStream(args->decompressor_ptr->ctx, args->out_buffer_ptr, args->in_buffer_ptr);

  return NULL;
}

VALUE zstds_ext_decompress(VALUE self, VALUE source_value)
{
  GET_DECOMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(decompressor_ptr);
  Check_Type(source_value, T_STRING);

  const char* source        = RSTRING_PTR(source_value);
  size_t      source_length = RSTRING_LEN(source_value);

  ZSTD_inBuffer  in_buffer  = {.src = source, .size = source_length, .pos = 0};
  ZSTD_outBuffer out_buffer = {
    .dst  = decompressor_ptr->remaining_destination_buffer,
    .size = decompressor_ptr->remaining_destination_buffer_length,
    .pos  = 0};

  decompress_args_t args = {
    .decompressor_ptr = decompressor_ptr, .in_buffer_ptr = &in_buffer, .out_buffer_ptr = &out_buffer};

  ZSTDS_EXT_GVL_WRAP(decompressor_ptr->gvl, decompress_wrapper, &args);
  if (ZSTD_isError(args.result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(args.result)));
  }

  decompressor_ptr->remaining_destination_buffer += out_buffer.pos;
  decompressor_ptr->remaining_destination_buffer_length -= out_buffer.pos;

  VALUE bytes_read             = SIZET2NUM(in_buffer.pos);
  VALUE needs_more_destination = decompressor_ptr->remaining_destination_buffer_length == 0 ? Qtrue : Qfalse;

  return rb_ary_new_from_args(2, bytes_read, needs_more_destination);
}

// -- other --

VALUE zstds_ext_decompressor_read_result(VALUE self)
{
  GET_DECOMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(decompressor_ptr);

  zstds_ext_byte_t* destination_buffer                  = decompressor_ptr->destination_buffer;
  size_t            destination_buffer_length           = decompressor_ptr->destination_buffer_length;
  size_t            remaining_destination_buffer_length = decompressor_ptr->remaining_destination_buffer_length;

  const char* result        = (const char*) destination_buffer;
  size_t      result_length = destination_buffer_length - remaining_destination_buffer_length;
  VALUE       result_value  = rb_str_new(result, result_length);

  decompressor_ptr->remaining_destination_buffer        = destination_buffer;
  decompressor_ptr->remaining_destination_buffer_length = destination_buffer_length;

  return result_value;
}

// -- cleanup --

VALUE zstds_ext_decompressor_close(VALUE self)
{
  GET_DECOMPRESSOR(self);
  DO_NOT_USE_AFTER_CLOSE(decompressor_ptr);

  ZSTD_DCtx* ctx = decompressor_ptr->ctx;
  if (ctx != NULL) {
    ZSTD_freeDCtx(ctx);

    decompressor_ptr->ctx = NULL;
  }

  zstds_ext_byte_t* destination_buffer = decompressor_ptr->destination_buffer;
  if (destination_buffer != NULL) {
    free(destination_buffer);

    decompressor_ptr->destination_buffer = NULL;
  }

  // It is possible to keep "destination_buffer_length", "remaining_destination_buffer"
  //   and "remaining_destination_buffer_length" as is.

  return Qnil;
}

// -- exports --

void zstds_ext_decompressor_exports(VALUE root_module)
{
  VALUE module = rb_define_module_under(root_module, "Stream");

  VALUE decompressor = rb_define_class_under(module, "NativeDecompressor", rb_cObject);

  rb_define_alloc_func(decompressor, zstds_ext_allocate_decompressor);
  rb_define_method(decompressor, "initialize", zstds_ext_initialize_decompressor, 1);
  rb_define_method(decompressor, "read", zstds_ext_decompress, 1);
  rb_define_method(decompressor, "read_result", zstds_ext_decompressor_read_result, 0);
  rb_define_method(decompressor, "close", zstds_ext_decompressor_close, 0);
}
