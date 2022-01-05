// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_MACRO_H)
#define ZSTDS_EXT_MACRO_H

#if defined(__GNUC__)
#define ZSTDS_EXT_UNUSED(x) x __attribute__((__unused__))
#else
#define ZSTDS_EXT_UNUSED(x) x
#endif

#if defined(__GNUC__)
#define ZSTDS_EXT_NORETURN __attribute__((__noreturn__))
#else
#define ZSTDS_EXT_NORETURN
#endif

#endif // ZSTDS_EXT_MACRO_H
