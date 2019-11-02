// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "ruby.h"
#include "zstds_ext/buffer.h"
#include "zstds_ext/common.h"
#include "zstds_ext/io.h"
#include "zstds_ext/option.h"
#include "zstds_ext/stream/compressor.h"
#include "zstds_ext/stream/decompressor.h"
#include "zstds_ext/string.h"

void Init_zstds_ext()
{
  VALUE root_module = rb_define_module(ZSTDS_EXT_MODULE_NAME);

  zstds_ext_buffer_exports(root_module);
  zstds_ext_io_exports(root_module);
  zstds_ext_option_exports(root_module);
  zstds_ext_compressor_exports(root_module);
  zstds_ext_decompressor_exports(root_module);
  zstds_ext_string_exports(root_module);
}
