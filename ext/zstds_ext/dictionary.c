// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/dictionary.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <zdict.h>

#include "ruby.h"
#include "zstds_ext/common.h"
#include "zstds_ext/error.h"
#include "zstds_ext/option.h"

static void free_dictionary(zstds_ext_dictionary_t* dictionary_ptr)
{
  uint8_t* buffer = dictionary_ptr->buffer;
  if (buffer != NULL) {
    free(buffer);
  }

  free(dictionary_ptr);
}

VALUE zstds_ext_allocate_dictionary(VALUE klass)
{
  zstds_ext_dictionary_t* dictionary_ptr;

  VALUE self = Data_Make_Struct(klass, zstds_ext_dictionary_t, NULL, free_dictionary, dictionary_ptr);

  dictionary_ptr->buffer = NULL;
  dictionary_ptr->size   = 0;

  return self;
}

#define GET_DICTIONARY(self)              \
  zstds_ext_dictionary_t* dictionary_ptr; \
  Data_Get_Struct(self, zstds_ext_dictionary_t, dictionary_ptr);

VALUE zstds_ext_initialize_dictionary(VALUE self, VALUE samples, VALUE options)
{
  GET_DICTIONARY(self);
  Check_Type(samples, T_ARRAY);

  size_t sample_index;
  size_t samples_length = RARRAY_LEN(samples);
  size_t samples_size   = 0;

  for (sample_index = 0; sample_index < samples_length; sample_index++) {
    VALUE sample = rb_ary_entry(samples, sample_index);
    Check_Type(sample, T_STRING);

    samples_size += RSTRING_LEN(sample);
  }

  Check_Type(options, T_HASH);
  ZSTDS_EXT_GET_BUFFER_LENGTH_OPTION(options, capacity);

  if (capacity == 0) {
    capacity = ZSTDS_EXT_DEFAULT_DICT_CAPACITY;
  }

  uint8_t* buffer = dictionary_ptr->buffer;
  if (buffer != NULL) {
    free(buffer);
  }

  buffer = malloc(capacity);
  if (buffer == NULL) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  uint8_t* samples_buffer = malloc(samples_size);
  if (samples_buffer == NULL) {
    free(buffer);
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_ALLOCATE_FAILED);
  }

  size_t* samples_sizes = malloc(samples_length * sizeof(size_t));
  if (samples_sizes == NULL) {
    free(buffer);
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

  zstds_result_t result = ZDICT_trainFromBuffer(buffer, capacity, samples_buffer, samples_sizes, samples_length);

  free(samples_buffer);
  free(samples_sizes);

  if (ZSTD_isError(result)) {
    free(buffer);
    zstds_ext_raise_error(zstds_ext_get_error(ZSTD_getErrorCode(result)));
  }

  dictionary_ptr->buffer = buffer;
  dictionary_ptr->size   = result;

  return Qnil;
}

VALUE zstds_ext_get_dictionary_size(VALUE self)
{
  GET_DICTIONARY(self);

  return SIZET2NUM(dictionary_ptr->size);
}

VALUE zstds_ext_get_dictionary_id(VALUE self)
{
  GET_DICTIONARY(self);

  if (dictionary_ptr->buffer == NULL) {
    return Qnil;
  }

  unsigned int id = ZDICT_getDictID(dictionary_ptr->buffer, dictionary_ptr->size);
  if (id == 0) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_VALIDATE_FAILED);
  }

  return UINT2NUM(id);
}

void zstds_ext_dictionary_exports(VALUE root_module)
{
  VALUE dictionary = rb_define_class_under(root_module, "NativeDictionary", rb_cObject);
  rb_define_alloc_func(dictionary, zstds_ext_allocate_dictionary);
  rb_define_method(dictionary, "initialize", zstds_ext_initialize_dictionary, 2);
  rb_define_method(dictionary, "size", zstds_ext_get_dictionary_size, 0);
  rb_define_method(dictionary, "id", zstds_ext_get_dictionary_id, 0);
}
