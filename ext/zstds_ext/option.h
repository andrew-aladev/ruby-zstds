// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_OPTIONS_H)
#define ZSTDS_EXT_OPTIONS_H

#include <stdbool.h>
#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/common.h"

// Default option values depends on zstd library.
// We will set only user defined values.

enum
{
  ZSTDS_EXT_OPTION_TYPE_BOOL = 1,
  ZSTDS_EXT_OPTION_TYPE_UINT,
  ZSTDS_EXT_OPTION_TYPE_INT,
  ZSTDS_EXT_OPTION_TYPE_STRATEGY
};

typedef zstds_ext_byte_fast_t zstds_ext_option_type_t;
typedef int                   zstds_ext_option_value_t;
typedef unsigned long long    zstds_ext_ull_option_value_t;

typedef struct
{
  bool                     has_value;
  zstds_ext_option_value_t value;
} zstds_ext_option_t;

typedef struct
{
  bool                         has_value;
  zstds_ext_ull_option_value_t value;
} zstds_ext_ull_option_t;

typedef struct
{
  zstds_ext_option_t     compression_level;
  zstds_ext_option_t     window_log;
  zstds_ext_option_t     hash_log;
  zstds_ext_option_t     chain_log;
  zstds_ext_option_t     search_log;
  zstds_ext_option_t     min_match;
  zstds_ext_option_t     target_length;
  zstds_ext_option_t     strategy;
  zstds_ext_option_t     enable_long_distance_matching;
  zstds_ext_option_t     ldm_hash_log;
  zstds_ext_option_t     ldm_min_match;
  zstds_ext_option_t     ldm_bucket_size_log;
  zstds_ext_option_t     ldm_hash_rate_log;
  zstds_ext_option_t     content_size_flag;
  zstds_ext_option_t     checksum_flag;
  zstds_ext_option_t     dict_id_flag;
  zstds_ext_option_t     nb_workers;
  zstds_ext_option_t     job_size;
  zstds_ext_option_t     overlap_log;
  zstds_ext_ull_option_t pledged_size;
  VALUE                  dictionary;
} zstds_ext_compressor_options_t;

typedef struct
{
  zstds_ext_option_t window_log_max;
  VALUE              dictionary;
} zstds_ext_decompressor_options_t;

void zstds_ext_resolve_option(
  VALUE                   options,
  zstds_ext_option_t*     option,
  zstds_ext_option_type_t type,
  const char*             name);

void zstds_ext_resolve_ull_option(VALUE options, zstds_ext_ull_option_t* option, const char* name);
void zstds_ext_resolve_dictionary_option(VALUE options, VALUE* option, const char* name);

#define ZSTDS_EXT_RESOLVE_OPTION(options, target_options, type, name) \
  zstds_ext_resolve_option(options, &target_options.name, type, #name);

#define ZSTDS_EXT_RESOLVE_ULL_OPTION(options, target_options, name) \
  zstds_ext_resolve_ull_option(options, &target_options.name, #name);

#define ZSTDS_EXT_RESOLVE_DICTIONARY_OPTION(options, target_options, name) \
  zstds_ext_resolve_dictionary_option(options, &target_options.name, #name);

#define ZSTDS_EXT_GET_COMPRESSOR_OPTIONS(options)                                                                   \
  zstds_ext_compressor_options_t compressor_options;                                                                \
                                                                                                                    \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_INT, compression_level);              \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, window_log);                    \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, hash_log);                      \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, chain_log);                     \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, search_log);                    \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, min_match);                     \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, target_length);                 \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_STRATEGY, strategy);                  \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_BOOL, enable_long_distance_matching); \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, ldm_hash_log);                  \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, ldm_min_match);                 \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, ldm_bucket_size_log);           \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, ldm_hash_rate_log);             \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_BOOL, content_size_flag);             \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_BOOL, checksum_flag);                 \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_BOOL, dict_id_flag);                  \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, nb_workers);                    \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, job_size);                      \
  ZSTDS_EXT_RESOLVE_OPTION(options, compressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, overlap_log);                   \
  ZSTDS_EXT_RESOLVE_ULL_OPTION(options, compressor_options, pledged_size);                                          \
  ZSTDS_EXT_RESOLVE_DICTIONARY_OPTION(options, compressor_options, dictionary);

#define ZSTDS_EXT_GET_DECOMPRESSOR_OPTIONS(options)                                                    \
  zstds_ext_decompressor_options_t decompressor_options;                                               \
                                                                                                       \
  ZSTDS_EXT_RESOLVE_OPTION(options, decompressor_options, ZSTDS_EXT_OPTION_TYPE_UINT, window_log_max); \
  ZSTDS_EXT_RESOLVE_DICTIONARY_OPTION(options, decompressor_options, dictionary);

bool   zstds_ext_get_bool_option_value(VALUE options, const char* name);
size_t zstds_ext_get_size_option_value(VALUE options, const char* name);

#define ZSTDS_EXT_GET_BOOL_OPTION(options, name) size_t name = zstds_ext_get_bool_option_value(options, #name);
#define ZSTDS_EXT_GET_SIZE_OPTION(options, name) size_t name = zstds_ext_get_size_option_value(options, #name);

zstds_ext_result_t zstds_ext_set_compressor_options(ZSTD_CCtx* ctx, zstds_ext_compressor_options_t* options);
zstds_ext_result_t zstds_ext_set_decompressor_options(ZSTD_DCtx* ctx, zstds_ext_decompressor_options_t* options);

void zstds_ext_option_exports(VALUE root_module);

#endif // ZSTDS_EXT_OPTIONS_H
