// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_DICTIONARY_H)
#define ZSTDS_EXT_DICTIONARY_H

#include "ruby.h"

#define ZSTDS_EXT_DEFAULT_DICTIONARY_CAPACITY (1 << 17); // 128 KB

VALUE zstds_ext_train_dictionary_buffer(VALUE self, VALUE samples, VALUE options);
VALUE zstds_ext_get_dictionary_buffer_id(VALUE self, VALUE buffer);

void zstds_ext_dictionary_exports(VALUE root_module);

#endif // ZSTDS_EXT_DICTIONARY_H
