// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/dictionary.h"

#include <string.h>
#include <zdict.h>

#include "zstds_ext/buffer.h"
#include "zstds_ext/error.h"
#include "zstds_ext/gvl.h"
#include "zstds_ext/option.h"

// -- common --

typedef struct
{
  const char* data;
  size_t      size;
} sample_t;

static inline void check_raw_samples(VALUE raw_samples)
{
  Check_Type(raw_samples, T_ARRAY);

  size_t samples_length = RARRAY_LEN(raw_samples);

  for (size_t index = 0; index < samples_length; index++) {
    Check_Type(rb_ary_entry(raw_samples, index), T_STRING);
  }
}

static inline sample_t* prepare_samples(VALUE raw_samples, size_t* samples_length_ptr)
{
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

  *samples_length_ptr = samples_length;

  return samples;
}

static inline zstds_ext_result_t prepare_samples_group(
  const sample_t*    samples,
  size_t             samples_length,
  zstds_ext_byte_t** group_ptr,
  size_t**           sizes_ptr)
{
  size_t size = 0;

  for (size_t index = 0; index < samples_length; index++) {
    size += samples[index].size;
  }

  zstds_ext_byte_t* group = malloc(size);
  if (group == NULL) {
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  size_t* sizes = malloc(samples_length * sizeof(size_t));
  if (sizes == NULL) {
    free(group);
    return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
  }

  size_t offset = 0;

  for (size_t index = 0; index < samples_length; index++) {
    const sample_t* sample_ptr  = &samples[index];
    size_t          sample_size = sample_ptr->size;

    memmove(group + offset, sample_ptr->data, sample_size);
    offset += sample_size;

    sizes[index] = sample_size;
  }

  *group_ptr = group;
  *sizes_ptr = sizes;

  return 0;
}

// -- training --

typedef struct
{
  const sample_t*    samples;
  size_t             samples_length;
  char*              buffer;
  size_t             capacity;
  zstds_result_t     result;
  zstds_ext_result_t ext_result;
} train_args_t;

static inline void* train_wrapper(void* data)
{
  train_args_t* args = data;

  zstds_ext_byte_t*  group;
  size_t*            sizes;
  zstds_ext_result_t result = prepare_samples_group(args->samples, args->samples_length, &group, &sizes);
  if (result != 0) {
    args->ext_result = result;
    return NULL;
  }

  args->result =
    ZDICT_trainFromBuffer((void*) args->buffer, args->capacity, group, sizes, (unsigned int) args->samples_length);

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

  size_t    samples_length;
  sample_t* samples = prepare_samples(raw_samples, &samples_length);

  if (capacity == 0) {
    capacity = ZSTDS_EXT_DEFAULT_DICTIONARY_CAPACITY;
  }

  int exception;

  ZSTDS_EXT_CREATE_STRING_BUFFER(buffer, capacity, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  train_args_t args = {
    .samples        = samples,
    .samples_length = samples_length,
    .buffer         = RSTRING_PTR(buffer),
    .capacity       = capacity,
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

// -- finalizing --

#if defined(HAVE_ZDICT_FINALIZE)
typedef struct
{
  const sample_t*                samples;
  size_t                         samples_length;
  char*                          buffer;
  size_t                         max_size;
  char*                          content;
  size_t                         content_length;
  zstds_ext_dictionary_options_t dictionary_options;
  zstds_result_t                 result;
  zstds_ext_result_t             ext_result;
} finalize_args_t;

static inline void* finalize_wrapper(void* data)
{
  finalize_args_t* args = data;

  zstds_ext_byte_t*  group;
  size_t*            sizes;
  zstds_ext_result_t result = prepare_samples_group(args->samples, args->samples_length, &group, &sizes);
  if (result != 0) {
    args->ext_result = result;
    return NULL;
  }

  int                compressionLevel  = 0;
  zstds_ext_option_t compression_level = args->dictionary_options.compression_level;
  if (compression_level.has_value) {
    compressionLevel = compression_level.value;
  }

  unsigned int       notificationLevel  = 0;
  zstds_ext_option_t notification_level = args->dictionary_options.notification_level;
  if (notification_level.has_value) {
    notificationLevel = notification_level.value;
  }

  unsigned int       dictID        = 0;
  zstds_ext_option_t dictionary_id = args->dictionary_options.dictionary_id;
  if (dictionary_id.has_value) {
    dictID = dictionary_id.value;
  }

  ZDICT_params_t dictionary_params = {
    .compressionLevel  = compressionLevel,
    .notificationLevel = notificationLevel,
    .dictID            = dictID,
  };

  args->result = ZDICT_finalizeDictionary(
    (void*) args->buffer,
    args->max_size,
    (void*) args->content,
    args->content_length,
    group,
    sizes,
    (unsigned int) args->samples_length,
    dictionary_params);

  free(group);
  free(sizes);

  if (ZDICT_isError(args->result)) {
    args->ext_result = zstds_ext_get_error(ZSTD_getErrorCode(args->result));
    return NULL;
  }

  args->ext_result = 0;

  return NULL;
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

  size_t    samples_length;
  sample_t* samples = prepare_samples(raw_samples, &samples_length);

  if (max_size == 0) {
    max_size = ZSTDS_EXT_DEFAULT_DICTIONARY_MAX_SIZE;
  }

  int exception;

  ZSTDS_EXT_CREATE_STRING_BUFFER(buffer, max_size, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  finalize_args_t args = {
    .samples            = samples,
    .samples_length     = samples_length,
    .buffer             = RSTRING_PTR(buffer),
    .max_size           = max_size,
    .content            = RSTRING_PTR(content),
    .content_length     = RSTRING_LEN(content),
    .dictionary_options = dictionary_options,
  };

  ZSTDS_EXT_GVL_WRAP(gvl, finalize_wrapper, &args);
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

#else
ZSTDS_EXT_NORETURN VALUE zstds_ext_finalize_dictionary_buffer(
  VALUE ZSTDS_EXT_UNUSED(self),
  VALUE ZSTDS_EXT_UNUSED(content),
  VALUE ZSTDS_EXT_UNUSED(raw_samples),
  VALUE ZSTDS_EXT_UNUSED(options))
{
  zstds_ext_raise_error(ZSTDS_EXT_ERROR_NOT_IMPLEMENTED);
}
#endif // HAVE_ZDICT_FINALIZE

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
VALUE zstds_ext_get_dictionary_header_size(VALUE ZSTDS_EXT_UNUSED(self), VALUE buffer)
{
  zstds_result_t result = ZDICT_getDictHeaderSize(RSTRING_PTR(buffer), RSTRING_LEN(buffer));
  if (ZDICT_isError(result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  return SIZET2NUM(result);
}

#else
ZSTDS_EXT_NORETURN VALUE
  zstds_ext_get_dictionary_header_size(VALUE ZSTDS_EXT_UNUSED(self), VALUE ZSTDS_EXT_UNUSED(buffer))
{
  zstds_ext_raise_error(ZSTDS_EXT_ERROR_NOT_IMPLEMENTED);
};
#endif // HAVE_ZDICT_HEADER_SIZE

// -- exports --

void zstds_ext_dictionary_exports(VALUE root_module)
{
  VALUE dictionary = rb_define_class_under(root_module, "Dictionary", rb_cObject);

  rb_define_singleton_method(dictionary, "finalize_buffer", zstds_ext_finalize_dictionary_buffer, 3);
  rb_define_singleton_method(dictionary, "get_buffer_id", zstds_ext_get_dictionary_buffer_id, 1);
  rb_define_singleton_method(dictionary, "get_header_size", zstds_ext_get_dictionary_header_size, 1);
  rb_define_singleton_method(dictionary, "train_buffer", zstds_ext_train_dictionary_buffer, 2);
}
