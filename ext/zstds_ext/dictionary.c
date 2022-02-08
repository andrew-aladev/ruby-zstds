// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/dictionary.h"

#include <string.h>
#include <zdict.h>

#include "zstds_ext/buffer.h"
#include "zstds_ext/error.h"
#include "zstds_ext/gvl.h"
#include "zstds_ext/option.h"

// -- initialization --

typedef struct
{
  const char* data;
  size_t      size;
} sample_t;

typedef struct
{
  const sample_t*    samples;
  size_t             length;
  char*              buffer;
  size_t             capacity;
  zstds_result_t     result;
  zstds_ext_result_t ext_result;
} train_args_t;

static inline void check_raw_samples(VALUE raw_samples)
{
  Check_Type(raw_samples, T_ARRAY);

  size_t length = RARRAY_LEN(raw_samples);

  for (size_t index = 0; index < length; index++) {
    Check_Type(rb_ary_entry(raw_samples, index), T_STRING);
  }
}

static inline void* train_wrapper(void* data)
{
  train_args_t*   args    = data;
  const sample_t* samples = args->samples;
  size_t          length  = args->length;
  size_t          size    = 0;

  for (size_t index = 0; index < length; index++) {
    size += samples[index].size;
  }

  zstds_ext_byte_t* group = malloc(size);
  if (group == NULL) {
    args->ext_result = ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
    return NULL;
  }

  size_t* sizes = malloc(length * sizeof(size_t));
  if (sizes == NULL) {
    free(group);
    args->ext_result = ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
    return NULL;
  }

  size_t offset = 0;

  for (size_t index = 0; index < length; index++) {
    const sample_t* sample_ptr  = &samples[index];
    size_t          sample_size = sample_ptr->size;

    memmove(group + offset, sample_ptr->data, sample_size);
    offset += sample_size;

    sizes[index] = sample_size;
  }

  args->result = ZDICT_trainFromBuffer((void*) args->buffer, args->capacity, group, sizes, (unsigned int) length);

  free(group);
  free(sizes);

  if (ZDICT_isError(args->result)) {
    args->ext_result = zstds_ext_get_error(ZSTD_getErrorCode(args->result));
    return NULL;
  }

  args->ext_result = 0;

  return NULL;
}

VALUE zstds_ext_train_dictionary_buffer(VALUE ZSTDS_EXT_UNUSED(self), VALUE raw_samples, VALUE options)
{
  check_raw_samples(raw_samples);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_SIZE_OPTION(options, capacity);
  ZSTDS_EXT_GET_BOOL_OPTION(options, gvl);

  if (capacity == 0) {
    capacity = ZSTDS_EXT_DEFAULT_DICTIONARY_CAPACITY;
  }

  int exception;

  ZSTDS_EXT_CREATE_STRING_BUFFER(buffer, capacity, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  size_t    samples_length = RARRAY_LEN(raw_samples);
  sample_t* samples        = malloc(sizeof(sample_t) * samples_length);
  if (samples == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  for (size_t index = 0; index < samples_length; index++) {
    VALUE     raw_sample = rb_ary_entry(raw_samples, index);
    sample_t* sample     = &samples[index];

    sample->data = RSTRING_PTR(raw_sample);
    sample->size = RSTRING_LEN(raw_sample);
  }

  train_args_t args = {
    .samples  = samples,
    .length   = samples_length,
    .buffer   = RSTRING_PTR(buffer),
    .capacity = capacity,
  };

  ZSTDS_EXT_GVL_WRAP(gvl, train_wrapper, &args);
  free(samples);

  if (args.ext_result != 0) {
    zstds_ext_raise_error(args.ext_result);
  }

  ZSTDS_EXT_RESIZE_STRING_BUFFER(buffer, args.result, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  return buffer;
}

VALUE zstds_ext_finalize_dictionary_buffer(
  VALUE ZSTDS_EXT_UNUSED(self),
  VALUE content,
  VALUE raw_samples,
  VALUE options)
{
  Check_Type(content, T_STRING);
  check_raw_samples(raw_samples);
  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_SIZE_OPTION(options, max_size);
  ZSTDS_EXT_GET_BOOL_OPTION(options, gvl);
  ZSTDS_EXT_GET_DICTIONARY_OPTIONS(options);

  if (max_size == 0) {
    max_size = ZSTDS_EXT_DEFAULT_DICTIONARY_MAX_SIZE;
  }
}

// -- other --

VALUE zstds_ext_get_dictionary_buffer_id(VALUE ZSTDS_EXT_UNUSED(self), VALUE buffer)
{
  unsigned int id = ZDICT_getDictID(RSTRING_PTR(buffer), RSTRING_LEN(buffer));
  if (id == 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_VALIDATE_FAILED);
  }

  return UINT2NUM(id);
}

#if defined(HAVE_ZDICT_HEADER_SIZE)
VALUE zstds_ext_get_dictionary_header_size(VALUE self, VALUE buffer)
{
  zstds_result_t result = ZDICT_getDictHeaderSize(RSTRING_PTR(buffer), RSTRING_LEN(buffer));
  if (ZDICT_isError(result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  return SIZET2NUM(result);
}

#else
ZSTDS_EXT_NORETURN VALUE zstds_ext_get_dictionary_header_size(VALUE self, VALUE buffer)
{
  zstds_ext_raise_error(ZSTDS_EXT_ERROR_NOT_IMPLEMENTED);
};
#endif

// -- exports --

void zstds_ext_dictionary_exports(VALUE root_module)
{
  VALUE dictionary = rb_define_class_under(root_module, "Dictionary", rb_cObject);

  rb_define_singleton_method(dictionary, "get_buffer_id", zstds_ext_get_dictionary_buffer_id, 1);
  rb_define_singleton_method(dictionary, "get_header_size", zstds_ext_get_dictionary_header_size, 1);
  rb_define_singleton_method(dictionary, "train_buffer", zstds_ext_train_dictionary_buffer, 2);
}
