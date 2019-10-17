// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_ERROR_H)
#define ZSTDS_EXT_ERROR_H

#include <zstd_errors.h>

#include "ruby.h"
#include "zstds_ext/common.h"

// Results for errors listed in "lib/zstds/error" used in c extension.

enum {
  ZSTDS_EXT_ERROR_ALLOCATE_FAILED = 1,
  ZSTDS_EXT_ERROR_VALIDATE_FAILED,

  ZSTDS_EXT_ERROR_USED_AFTER_CLOSE,
  ZSTDS_EXT_ERROR_NOT_ENOUGH_SOURCE_BUFFER,
  ZSTDS_EXT_ERROR_NOT_ENOUGH_DESTINATION_BUFFER,
  ZSTDS_EXT_ERROR_DECOMPRESSOR_CORRUPTED_SOURCE,

  ZSTDS_EXT_ERROR_ACCESS_IO,
  ZSTDS_EXT_ERROR_READ_IO,
  ZSTDS_EXT_ERROR_WRITE_IO,

  ZSTDS_EXT_ERROR_UNEXPECTED
};

zstds_ext_result_t zstds_ext_get_error(ZSTD_ErrorCode error_code);

NORETURN(void zstds_ext_raise_error(zstds_ext_result_t ext_result));

#endif // ZSTDS_EXT_ERROR_H
