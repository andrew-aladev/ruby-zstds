// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/error.h"

#include <zstd_errors.h>

#include "ruby.h"
#include "zstds_ext/common.h"

zstds_ext_result_t zstds_ext_get_error(ZSTD_ErrorCode error_code)
{
  switch (error_code) {
    case ZSTD_error_memory_allocation:
      return ZSTDS_EXT_ERROR_ALLOCATE_FAILED;
    case ZSTD_error_parameter_unsupported:
    case ZSTD_error_parameter_outOfBound:
    case ZSTD_error_tableLog_tooLarge:
    case ZSTD_error_maxSymbolValue_tooLarge:
    case ZSTD_error_maxSymbolValue_tooSmall:
    case ZSTD_error_workSpace_tooSmall:
    case ZSTD_error_srcSize_wrong:
    case ZSTD_error_dstSize_tooSmall:
    case ZSTD_error_dstBuffer_null:
      return ZSTDS_EXT_ERROR_VALIDATE_FAILED;
    case ZSTD_error_prefix_unknown:
    case ZSTD_error_version_unsupported:
    case ZSTD_error_frameParameter_unsupported:
    case ZSTD_error_frameParameter_windowTooLarge:
    case ZSTD_error_corruption_detected:
    case ZSTD_error_checksum_wrong:
      return ZSTDS_EXT_ERROR_DECOMPRESSOR_CORRUPTED_SOURCE;
    default:
      return ZSTDS_EXT_ERROR_UNEXPECTED;
  }
}

static inline NORETURN(void raise(const char *name, const char *description))
{
  VALUE module = rb_define_module(ZSTDS_EXT_MODULE_NAME);
  VALUE error  = rb_const_get(module, rb_intern(name));
  rb_raise(error, "%s", description);
}

void zstds_ext_raise_error(zstds_ext_result_t result)
{
  switch (result) {
    case ZSTDS_EXT_ERROR_ALLOCATE_FAILED:
      raise("AllocateError", "allocate error");
    case ZSTDS_EXT_ERROR_VALIDATE_FAILED:
      raise("ValidateError", "validate error");

    case ZSTDS_EXT_ERROR_USED_AFTER_CLOSE:
      raise("UsedAfterCloseError", "used after closed");
    case ZSTDS_EXT_ERROR_NOT_ENOUGH_SOURCE_BUFFER:
      raise("NotEnoughSourceBufferError", "not enough source buffer");
    case ZSTDS_EXT_ERROR_NOT_ENOUGH_DESTINATION_BUFFER:
      raise("NotEnoughDestinationBufferError", "not enough destination buffer");
    case ZSTDS_EXT_ERROR_DECOMPRESSOR_CORRUPTED_SOURCE:
      raise("DecompressorCorruptedSourceError", "decompressor received corrupted source");

    case ZSTDS_EXT_ERROR_ACCESS_IO:
      raise("AccessIOError", "failed to access IO");
    case ZSTDS_EXT_ERROR_READ_IO:
      raise("ReadIOError", "failed to read IO");
    case ZSTDS_EXT_ERROR_WRITE_IO:
      raise("WriteIOError", "failed to write IO");

    default:
      // ZSTDS_EXT_ERROR_UNEXPECTED
      raise("UnexpectedError", "unexpected error");
  }
}
