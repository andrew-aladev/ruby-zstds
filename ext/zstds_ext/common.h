// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_COMMON_H)
#define ZSTDS_EXT_COMMON_H

#include <stdint.h>
#include <stdlib.h>

#define ZSTDS_EXT_MODULE_NAME "ZSTDS"

// WARNING: zstd library are mixing size and error codes inside size_t, dangerous.
typedef size_t       zstds_result_t;
typedef uint_fast8_t zstds_ext_result_t;

typedef uint8_t      zstds_ext_byte_t;
typedef uint_fast8_t zstds_ext_byte_fast_t;

#endif // ZSTDS_EXT_COMMON_H
