// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_MACRO_H)
#define ZSTDS_EXT_MACRO_H

#if defined(__GNUC__)
#define ZSTDS_EXT_UNUSED(x) x __attribute__((__unused__))
#else
#define ZSTDS_EXT_UNUSED(x) x
#endif

#endif // ZSTDS_EXT_MACRO_H
