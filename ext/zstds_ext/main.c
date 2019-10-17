// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "ruby.h"
#include "zstds_ext/common.h"
#include "zstds_ext/option.h"

void Init_zstds_ext()
{
  VALUE root_module = rb_define_module(ZSTDS_EXT_MODULE_NAME);

  zstds_ext_option_exports(root_module);
}
