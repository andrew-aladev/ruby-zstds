// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/dictionary.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <zdict.h>

#include "ruby.h"
#include "zstds_ext/buffer.h"
#include "zstds_ext/common.h"
#include "zstds_ext/error.h"
#include "zstds_ext/option.h"

VALUE zstds_ext_initialize_dictionary(VALUE self, VALUE buffer)
{
  if (rb_obj_is_kind_of(buffer, rb_cString) != Qtrue || RSTRING_LEN(buffer) == 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_VALIDATE_FAILED);
  }

  rb_iv_set(self, "@buffer", buffer);

  return Qnil;
}

VALUE zstds_ext_get_dictionary_id(VALUE self)
{
  VALUE buffer = rb_attr_get(self, rb_intern("@buffer"));

  unsigned int id = ZDICT_getDictID(RSTRING_PTR(buffer), RSTRING_LEN(buffer));
  if (id == 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_VALIDATE_FAILED);
  }

  return UINT2NUM(id);
}

VALUE zstds_ext_train_dictionary(VALUE self, VALUE samples, VALUE options)
{
  Check_Type(samples, T_ARRAY);

  size_t       sample_index;
  unsigned int samples_length = (unsigned int)RARRAY_LEN(samples);
  size_t       samples_size   = 0;

  for (sample_index = 0; sample_index < samples_length; sample_index++) {
    VALUE sample = rb_ary_entry(samples, sample_index);
    Check_Type(sample, T_STRING);

    samples_size += RSTRING_LEN(sample);
  }

  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_BUFFER_LENGTH_OPTION(options, capacity);

  if (capacity == 0) {
    capacity = ZSTDS_EXT_DEFAULT_DICTIONARY_CAPACITY;
  }

  int exception;

  ZSTDS_EXT_CREATE_STRING_BUFFER(buffer, capacity, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  uint8_t* samples_buffer = malloc(samples_size);
  if (samples_buffer == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  size_t* samples_sizes = malloc(samples_length * sizeof(size_t));
  if (samples_sizes == NULL) {
    free(samples_buffer);
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  size_t sample_offset = 0;

  for (sample_index = 0; sample_index < samples_length; sample_index++) {
    VALUE       sample      = rb_ary_entry(samples, sample_index);
    const char* sample_data = RSTRING_PTR(sample);
    size_t      sample_size = RSTRING_LEN(sample);

    memmove(samples_buffer + sample_offset, sample_data, sample_size);
    sample_offset += sample_size;

    samples_sizes[sample_index] = sample_size;
  }

  zstds_result_t result = ZDICT_trainFromBuffer(
    RSTRING_PTR(buffer), capacity,
    samples_buffer, samples_sizes, samples_length);

  free(samples_buffer);
  free(samples_sizes);

  if (ZSTD_isError(result)) {
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  ZSTDS_EXT_RESIZE_STRING_BUFFER(buffer, result, exception);
  if (exception != 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  return rb_class_new_instance(1, &buffer, RCLASS_SUPER(self));
}

void zstds_ext_dictionary_exports(VALUE root_module)
{
  VALUE dictionary = rb_define_class_under(root_module, "NativeDictionary", rb_cObject);

  rb_attr(dictionary, rb_intern("buffer"), 1, 0, 0);

  rb_define_method(dictionary, "initialize", zstds_ext_initialize_dictionary, 1);
  rb_define_method(dictionary, "id", zstds_ext_get_dictionary_id, 0);
  rb_define_singleton_method(dictionary, "train", zstds_ext_train_dictionary, 2);
}
