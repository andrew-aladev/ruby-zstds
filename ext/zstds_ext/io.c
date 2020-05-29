// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "ruby/io.h"

#include <stdio.h>
#include <string.h>
#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/error.h"
#include "zstds_ext/io.h"
#include "zstds_ext/macro.h"
#include "zstds_ext/option.h"

// Additional possible results:
enum {
  ZSTDS_EXT_FILE_READ_FINISHED = 128
};

// -- file --

static inline zstds_ext_result_t read_file(FILE* source_file, zstds_ext_byte_t* source_buffer, size_t* source_length_ptr, size_t source_buffer_length)
{
  size_t read_length = fread(source_buffer, 1, source_buffer_length, source_file);
  if (read_length == 0 && feof(source_file)) {
    return ZSTDS_EXT_FILE_READ_FINISHED;
  }

  if (read_length != source_buffer_length && ferror(source_file)) {
    return ZSTDS_EXT_ERROR_READ_IO;
  }

  *source_length_ptr = read_length;

  return 0;
}

static inline zstds_ext_result_t write_file(FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t destination_length)
{
  size_t written_length = fwrite(destination_buffer, 1, destination_length, destination_file);
  if (written_length != destination_length) {
    return ZSTDS_EXT_ERROR_WRITE_IO;
  }

  return 0;
}

// -- buffer --

static inline zstds_ext_result_t create_buffers(
  zstds_ext_byte_t** source_buffer_ptr, size_t source_buffer_length,
  zstds_ext_byte_t** destination_buffer_ptr, size_t destination_buffer_length)
{
  zstds_ext_byte_t* source_buffer = malloc(source_buffer_length);
  if (source_buffer == NULL) {
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  zstds_ext_byte_t* destination_buffer = malloc(destination_buffer_length);
  if (destination_buffer == NULL) {
    free(source_buffer);
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  *source_buffer_ptr      = source_buffer;
  *destination_buffer_ptr = destination_buffer;

  return 0;
}

// We have read some source from file into source buffer.
// Than algorithm has read part of this source.
// We need to move remaining source to the top of source buffer.
// Than we can read more source from file.
// Algorithm can use same buffer again.

static inline zstds_ext_result_t read_more_source(
  FILE*                    source_file,
  const zstds_ext_byte_t** source_ptr, size_t* source_length_ptr,
  zstds_ext_byte_t* source_buffer, size_t source_buffer_length)
{
  const zstds_ext_byte_t* source        = *source_ptr;
  size_t                  source_length = *source_length_ptr;

  if (source != source_buffer) {
    if (source_length != 0) {
      memmove(source_buffer, source, source_length);
    }

    // Source can be accessed even if next code will fail.
    *source_ptr = source_buffer;
  }

  size_t remaining_source_buffer_length = source_buffer_length - source_length;
  if (remaining_source_buffer_length == 0) {
    // We want to read more data at once, than buffer has.
    return ZSTDS_EXT_ERROR_NOT_ENOUGH_SOURCE_BUFFER;
  }

  zstds_ext_byte_t* remaining_source_buffer = source_buffer + source_length;
  size_t            new_source_length;

  zstds_ext_result_t ext_result = read_file(source_file, remaining_source_buffer, &new_source_length, remaining_source_buffer_length);
  if (ext_result != 0) {
    return ext_result;
  }

  *source_length_ptr = source_length + new_source_length;

  return 0;
}

#define BUFFERED_READ_SOURCE(function, ...)                 \
  do {                                                      \
    bool is_function_called = false;                        \
                                                            \
    while (true) {                                          \
      ext_result = read_more_source(                        \
        source_file,                                        \
        &source, &source_length,                            \
        source_buffer, source_buffer_length);               \
                                                            \
      if (ext_result == ZSTDS_EXT_FILE_READ_FINISHED) {     \
        if (source_length != 0) {                           \
          /* ZSTD won't provide any remainder by design. */ \
          return ZSTDS_EXT_ERROR_READ_IO;                   \
        }                                                   \
        break;                                              \
      }                                                     \
      else if (ext_result != 0) {                           \
        return ext_result;                                  \
      }                                                     \
                                                            \
      ext_result = function(__VA_ARGS__);                   \
      if (ext_result != 0) {                                \
        return ext_result;                                  \
      }                                                     \
                                                            \
      is_function_called = true;                            \
    }                                                       \
                                                            \
    if (!is_function_called) {                              \
      /* Function should be called at least once. */        \
      ext_result = function(__VA_ARGS__);                   \
      if (ext_result != 0) {                                \
        return ext_result;                                  \
      }                                                     \
    }                                                       \
  } while (false);

// Algorithm has written data into destination buffer.
// We need to write this data into file.
// Than algorithm can use same buffer again.

static inline zstds_ext_result_t flush_destination_buffer(
  FILE*             destination_file,
  zstds_ext_byte_t* destination_buffer, size_t* destination_length_ptr, size_t destination_buffer_length)
{
  if (*destination_length_ptr == 0) {
    // We want to write more data at once, than buffer has.
    return ZSTDS_EXT_ERROR_NOT_ENOUGH_DESTINATION_BUFFER;
  }

  zstds_ext_result_t ext_result = write_file(destination_file, destination_buffer, *destination_length_ptr);
  if (ext_result != 0) {
    return ext_result;
  }

  *destination_length_ptr = 0;

  return 0;
}

static inline zstds_ext_result_t write_remaining_destination(FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t destination_length)
{
  if (destination_length == 0) {
    return 0;
  }

  return write_file(destination_file, destination_buffer, destination_length);
}

// -- utils --

#define GET_FILE(target)                               \
  Check_Type(target, T_FILE);                          \
                                                       \
  rb_io_t* target##_io;                                \
  GetOpenFile(target, target##_io);                    \
                                                       \
  FILE* target##_file = rb_io_stdio_file(target##_io); \
  if (target##_file == NULL) {                         \
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ACCESS_IO);  \
  }

// -- compress --

static inline zstds_ext_result_t buffered_compress(
  ZSTD_CCtx*               ctx,
  const zstds_ext_byte_t** source_ptr, size_t* source_length_ptr,
  FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t* destination_length_ptr, size_t destination_buffer_length)
{
  zstds_result_t     result;
  zstds_ext_result_t ext_result;

  ZSTD_inBuffer in_buffer;
  in_buffer.src  = *source_ptr;
  in_buffer.size = *source_length_ptr;
  in_buffer.pos  = 0;

  ZSTD_outBuffer out_buffer;

  while (true) {
    out_buffer.dst  = destination_buffer + *destination_length_ptr;
    out_buffer.size = destination_buffer_length - *destination_length_ptr;
    out_buffer.pos  = 0;

    result = ZSTD_compressStream2(ctx, &out_buffer, &in_buffer, ZSTD_e_continue);
    if (ZSTD_isError(result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(result));
    }

    *destination_length_ptr += out_buffer.pos;

    if (*destination_length_ptr == destination_buffer_length) {
      ext_result = flush_destination_buffer(
        destination_file,
        destination_buffer, destination_length_ptr, destination_buffer_length);

      if (ext_result != 0) {
        return ext_result;
      }

      continue;
    }

    break;
  }

  *source_ptr += in_buffer.pos;
  *source_length_ptr -= in_buffer.pos;

  return 0;
}

static inline zstds_ext_result_t buffered_compressor_finish(
  ZSTD_CCtx* ctx,
  FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t* destination_length_ptr, size_t destination_buffer_length)
{
  zstds_result_t     result;
  zstds_ext_result_t ext_result;

  ZSTD_inBuffer in_buffer;
  in_buffer.src  = NULL;
  in_buffer.size = 0;
  in_buffer.pos  = 0;

  ZSTD_outBuffer out_buffer;

  while (true) {
    out_buffer.dst  = destination_buffer + *destination_length_ptr;
    out_buffer.size = destination_buffer_length - *destination_length_ptr;
    out_buffer.pos  = 0;

    result = ZSTD_compressStream2(ctx, &out_buffer, &in_buffer, ZSTD_e_end);
    if (ZSTD_isError(result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(result));
    }

    *destination_length_ptr += out_buffer.pos;

    if (result != 0) {
      ext_result = flush_destination_buffer(
        destination_file,
        destination_buffer, destination_length_ptr, destination_buffer_length);

      if (ext_result != 0) {
        return ext_result;
      }

      continue;
    }

    break;
  }

  return 0;
}

static inline zstds_ext_result_t compress(
  ZSTD_CCtx* ctx,
  FILE* source_file, zstds_ext_byte_t* source_buffer, size_t source_buffer_length,
  FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t destination_buffer_length)
{
  zstds_ext_result_t ext_result;

  const zstds_ext_byte_t* source             = source_buffer;
  size_t                  source_length      = 0;
  size_t                  destination_length = 0;

  BUFFERED_READ_SOURCE(
    buffered_compress,
    ctx,
    &source, &source_length,
    destination_file, destination_buffer, &destination_length, destination_buffer_length);

  ext_result = buffered_compressor_finish(
    ctx,
    destination_file, destination_buffer, &destination_length, destination_buffer_length);

  if (ext_result != 0) {
    return ext_result;
  }

  return write_remaining_destination(destination_file, destination_buffer, destination_length);
}

VALUE zstds_ext_compress_io(VALUE ZSTDS_EXT_UNUSED(self), VALUE source, VALUE destination, VALUE options)
{
  GET_FILE(source);
  GET_FILE(destination);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_COMPRESSOR_OPTIONS(options);
  ZSTDS_EXT_GET_BUFFER_LENGTH_OPTION(options, source_buffer_length);
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

  if (source_buffer_length == 0) {
    source_buffer_length = ZSTD_CStreamInSize();
  }
  if (destination_buffer_length == 0) {
    destination_buffer_length = ZSTD_CStreamOutSize();
  }

  zstds_ext_byte_t* source_buffer;
  zstds_ext_byte_t* destination_buffer;

  ext_result = create_buffers(
    &source_buffer, source_buffer_length,
    &destination_buffer, destination_buffer_length);

  if (ext_result != 0) {
    ZSTD_freeCCtx(ctx);
    zstds_ext_raise_error(ext_result);
  }

  ext_result = compress(
    ctx,
    source_file, source_buffer, source_buffer_length,
    destination_file, destination_buffer, destination_buffer_length);

  free(source_buffer);
  free(destination_buffer);
  ZSTD_freeCCtx(ctx);

  if (ext_result != 0) {
    zstds_ext_raise_error(ext_result);
  }

  // Ruby itself won't flush stdio file before closing fd, flush is required.
  fflush(destination_file);

  return Qnil;
}

// -- decompress --

static inline zstds_ext_result_t buffered_decompress(
  ZSTD_DCtx*               ctx,
  const zstds_ext_byte_t** source_ptr, size_t* source_length_ptr,
  FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t* destination_length_ptr, size_t destination_buffer_length)
{
  zstds_result_t     result;
  zstds_ext_result_t ext_result;

  ZSTD_inBuffer in_buffer;
  in_buffer.src  = *source_ptr;
  in_buffer.size = *source_length_ptr;
  in_buffer.pos  = 0;

  ZSTD_outBuffer out_buffer;

  while (true) {
    out_buffer.dst  = destination_buffer + *destination_length_ptr;
    out_buffer.size = destination_buffer_length - *destination_length_ptr;
    out_buffer.pos  = 0;

    result = ZSTD_decompressStream(ctx, &out_buffer, &in_buffer);
    if (ZSTD_isError(result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(result));
    }

    *destination_length_ptr += out_buffer.pos;

    if (*destination_length_ptr == destination_buffer_length) {
      ext_result = flush_destination_buffer(
        destination_file,
        destination_buffer, destination_length_ptr, destination_buffer_length);

      if (ext_result != 0) {
        return ext_result;
      }

      continue;
    }

    break;
  }

  *source_ptr += in_buffer.pos;
  *source_length_ptr -= in_buffer.pos;

  return 0;
}

static inline zstds_ext_result_t decompress(
  ZSTD_DCtx* ctx,
  FILE* source_file, zstds_ext_byte_t* source_buffer, size_t source_buffer_length,
  FILE* destination_file, zstds_ext_byte_t* destination_buffer, size_t destination_buffer_length)
{
  zstds_ext_result_t ext_result;

  const zstds_ext_byte_t* source             = source_buffer;
  size_t                  source_length      = 0;
  size_t                  destination_length = 0;

  BUFFERED_READ_SOURCE(
    buffered_decompress,
    ctx,
    &source, &source_length,
    destination_file, destination_buffer, &destination_length, destination_buffer_length);

  return write_remaining_destination(destination_file, destination_buffer, destination_length);
}

VALUE zstds_ext_decompress_io(VALUE ZSTDS_EXT_UNUSED(self), VALUE source, VALUE destination, VALUE options)
{
  GET_FILE(source);
  GET_FILE(destination);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_DECOMPRESSOR_OPTIONS(options);
  ZSTDS_EXT_GET_BUFFER_LENGTH_OPTION(options, source_buffer_length);
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

  if (source_buffer_length == 0) {
    source_buffer_length = ZSTD_DStreamInSize();
  }
  if (destination_buffer_length == 0) {
    destination_buffer_length = ZSTD_DStreamOutSize();
  }

  zstds_ext_byte_t* source_buffer;
  zstds_ext_byte_t* destination_buffer;

  ext_result = create_buffers(
    &source_buffer, source_buffer_length,
    &destination_buffer, destination_buffer_length);

  if (ext_result != 0) {
    ZSTD_freeDCtx(ctx);
    zstds_ext_raise_error(ext_result);
  }

  ext_result = decompress(
    ctx,
    source_file, source_buffer, source_buffer_length,
    destination_file, destination_buffer, destination_buffer_length);

  free(source_buffer);
  free(destination_buffer);
  ZSTD_freeDCtx(ctx);

  if (ext_result != 0) {
    zstds_ext_raise_error(ext_result);
  }

  // Ruby itself won't flush stdio file before closing fd, flush is required.
  fflush(destination_file);

  return Qnil;
}

void zstds_ext_io_exports(VALUE root_module)
{
  rb_define_module_function(root_module, "_native_compress_io", RUBY_METHOD_FUNC(zstds_ext_compress_io), 3);
  rb_define_module_function(root_module, "_native_decompress_io", RUBY_METHOD_FUNC(zstds_ext_decompress_io), 3);
}
