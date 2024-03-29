// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/error.h"

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
    case ZSTD_error_stage_wrong:
    case ZSTD_error_init_missing:
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
    case ZSTD_error_dictionary_corrupted:
    case ZSTD_error_dictionary_wrong:
    case ZSTD_error_dictionaryCreation_failed:
      return ZSTDS_EXT_ERROR_CORRUPTED_DICTIONARY;
    default:
      return ZSTDS_EXT_ERROR_UNEXPECTED;
  }
}

static inline NORETURN(void raise_error(const char* name, const char* description))
{
  VALUE module = rb_define_module(ZSTDS_EXT_MODULE_NAME);
  VALUE error  = rb_const_get(module, rb_intern(name));
  rb_raise(error, "%s", description);
}

void zstds_ext_raise_error(zstds_ext_result_t ext_result)
{
  switch (ext_result) {
    case ZSTDS_EXT_ERROR_ALLOCATE_FAILED:
      raise_error("AllocateError", "allocate error");
    case ZSTDS_EXT_ERROR_VALIDATE_FAILED:
      raise_error("ValidateError", "validate error");

    case ZSTDS_EXT_ERROR_USED_AFTER_CLOSE:
      raise_error("UsedAfterCloseError", "used after closed");
    case ZSTDS_EXT_ERROR_NOT_ENOUGH_SOURCE_BUFFER:
      raise_error("NotEnoughSourceBufferError", "not enough source buffer");
    case ZSTDS_EXT_ERROR_NOT_ENOUGH_DESTINATION_BUFFER:
      raise_error("NotEnoughDestinationBufferError", "not enough destination buffer");
    case ZSTDS_EXT_ERROR_DECOMPRESSOR_CORRUPTED_SOURCE:
      raise_error("DecompressorCorruptedSourceError", "decompressor received corrupted source");
    case ZSTDS_EXT_ERROR_CORRUPTED_DICTIONARY:
      raise_error("CorruptedDictionaryError", "corrupted dictionary");

    case ZSTDS_EXT_ERROR_ACCESS_IO:
      raise_error("AccessIOError", "failed to access IO");
    case ZSTDS_EXT_ERROR_READ_IO:
      raise_error("ReadIOError", "failed to read IO");
    case ZSTDS_EXT_ERROR_WRITE_IO:
      raise_error("WriteIOError", "failed to write IO");

    case ZSTDS_EXT_ERROR_NOT_IMPLEMENTED:
      raise_error("NotImplementedError", "not implemented error");

    default:
      // ZSTDS_EXT_ERROR_UNEXPECTED
      raise_error("UnexpectedError", "unexpected error");
  }
}
