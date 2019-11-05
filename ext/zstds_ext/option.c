// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#include "zstds_ext/option.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <zstd.h>

#include "ruby.h"
#include "zstds_ext/common.h"
#include "zstds_ext/dictionary.h"
#include "zstds_ext/error.h"

// -- values --

static inline VALUE get_raw_option_value(VALUE options, const char* name)
{
  return rb_funcall(options, rb_intern("[]"), 1, ID2SYM(rb_intern(name)));
}

static inline bool get_bool_option_value(VALUE raw_value)
{
  int raw_type = TYPE(raw_value);
  if (raw_type != T_TRUE && raw_type != T_FALSE) {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_VALIDATE_FAILED);
  }

  return raw_type == T_TRUE;
}

static inline unsigned int get_uint_option_value(VALUE raw_value)
{
  Check_Type(raw_value, T_FIXNUM);

  return NUM2UINT(raw_value);
}

static inline int get_int_option_value(VALUE raw_value)
{
  Check_Type(raw_value, T_FIXNUM);

  return NUM2INT(raw_value);
}

static inline unsigned long long get_ull_option_value(VALUE raw_value)
{
  Check_Type(raw_value, T_FIXNUM);

  return NUM2ULL(raw_value);
}

static inline ZSTD_strategy get_strategy_option_value(VALUE raw_value)
{
  Check_Type(raw_value, T_SYMBOL);

  ID raw_id = SYM2ID(raw_value);
  if (raw_id == rb_intern("fast")) {
    return ZSTD_fast;
  }
  else if (raw_id == rb_intern("dfast")) {
    return ZSTD_dfast;
  }
  else if (raw_id == rb_intern("greedy")) {
    return ZSTD_greedy;
  }
  else if (raw_id == rb_intern("lazy")) {
    return ZSTD_lazy;
  }
  else if (raw_id == rb_intern("lazy2")) {
    return ZSTD_lazy2;
  }
  else if (raw_id == rb_intern("btlazy2")) {
    return ZSTD_btlazy2;
  }
  else if (raw_id == rb_intern("btopt")) {
    return ZSTD_btopt;
  }
  else if (raw_id == rb_intern("btultra")) {
    return ZSTD_btultra;
  }
  else if (raw_id == rb_intern("btultra2")) {
    return ZSTD_btultra2;
  }
  else {
    zstds_ext_raise_error(ZSTDS_EXT_ERROR_VALIDATE_FAILED);
  }
}

void zstds_ext_get_option(VALUE options, zstds_ext_option_t* option, zstds_ext_option_type_t type, const char* name)
{
  VALUE raw_value = get_raw_option_value(options, name);

  option->has_value = raw_value != Qnil;
  if (!option->has_value) {
    return;
  }

  zstds_ext_option_value_t value;

  switch (type) {
    case ZSTDS_EXT_OPTION_TYPE_BOOL:
      value = get_bool_option_value(raw_value) ? 1 : 0;
      break;
    case ZSTDS_EXT_OPTION_TYPE_UINT:
      value = (zstds_ext_option_value_t)get_uint_option_value(raw_value);
      break;
    case ZSTDS_EXT_OPTION_TYPE_INT:
      value = (zstds_ext_option_value_t)get_int_option_value(raw_value);
      break;
    case ZSTDS_EXT_OPTION_TYPE_STRATEGY:
      value = (zstds_ext_option_value_t)get_strategy_option_value(raw_value);
      break;
    default:
      zstds_ext_raise_error(ZSTDS_EXT_ERROR_UNEXPECTED);
  }

  option->value = value;
}

void zstds_ext_get_ull_option(VALUE options, zstds_ext_ull_option_t* option, const char* name)
{
  VALUE raw_value = get_raw_option_value(options, name);

  option->has_value = raw_value != Qnil;
  if (option->has_value) {
    option->value = (zstds_ext_ull_option_value_t)get_ull_option_value(raw_value);
  }
}

void zstds_ext_get_value_option(VALUE options, VALUE* option, const char* name)
{
  *option = get_raw_option_value(options, name);
}

size_t zstds_ext_get_size_option_value(VALUE options, const char* name)
{
  VALUE raw_value = get_raw_option_value(options, name);

  Check_Type(raw_value, T_FIXNUM);

  return NUM2SIZET(raw_value);
}

// -- set params --

#define SET_OPTION_VALUE(function, ctx, param, option)       \
  if (option.has_value) {                                    \
    result = function(ctx, param, option.value);             \
    if (ZSTD_isError(result)) {                              \
      return zstds_ext_get_error(ZSTD_getErrorCode(result)); \
    }                                                        \
  }

#define SET_COMPRESSOR_PARAM(ctx, param, option) \
  SET_OPTION_VALUE(ZSTD_CCtx_setParameter, ctx, param, option);

#define GET_DICTIONARY(dictionary)        \
  zstds_ext_dictionary_t* dictionary_ptr; \
  Data_Get_Struct(dictionary, zstds_ext_dictionary_t, dictionary_ptr);

zstds_ext_result_t zstds_ext_set_compressor_options(ZSTD_CCtx* ctx, zstds_ext_compressor_options_t* options)
{
  zstds_result_t result;

  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_compressionLevel, options->compression_level);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_windowLog, options->window_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_hashLog, options->hash_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_chainLog, options->chain_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_searchLog, options->search_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_minMatch, options->min_match);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_targetLength, options->target_length);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_strategy, options->strategy);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_enableLongDistanceMatching, options->enable_long_distance_matching);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_ldmHashLog, options->ldm_hash_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_ldmMinMatch, options->ldm_min_match);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_ldmBucketSizeLog, options->ldm_bucket_size_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_ldmHashRateLog, options->ldm_hash_rate_log);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_contentSizeFlag, options->content_size_flag);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_checksumFlag, options->checksum_flag);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_dictIDFlag, options->dict_id_flag);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_nbWorkers, options->nb_workers);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_jobSize, options->job_size);
  SET_COMPRESSOR_PARAM(ctx, ZSTD_c_overlapLog, options->overlap_log);

  if (options->pledged_size.has_value) {
    result = ZSTD_CCtx_setPledgedSrcSize(ctx, options->pledged_size.value);
    if (ZSTD_isError(result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(result));
    }
  }

  if (options->dictionary != Qnil) {
    GET_DICTIONARY(options->dictionary);
    result = ZSTD_CCtx_loadDictionary(ctx, dictionary_ptr->buffer, dictionary_ptr->size);
    if (ZSTD_isError(result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(result));
    }
  }

  return 0;
}

#define SET_DECOMPRESSOR_PARAM(ctx, param, option) \
  SET_OPTION_VALUE(ZSTD_DCtx_setParameter, ctx, param, option);

zstds_ext_result_t zstds_ext_set_decompressor_options(ZSTD_DCtx* ctx, zstds_ext_decompressor_options_t* options)
{
  zstds_result_t result;

  SET_DECOMPRESSOR_PARAM(ctx, ZSTD_d_windowLogMax, options->window_log_max);

  if (options->dictionary != Qnil) {
    GET_DICTIONARY(options->dictionary);
    result = ZSTD_DCtx_loadDictionary(ctx, dictionary_ptr->buffer, dictionary_ptr->size);
    if (ZSTD_isError(result)) {
      return zstds_ext_get_error(ZSTD_getErrorCode(result));
    }
  }

  return 0;
}

// -- exports --

#define EXPORT_PARAM_BOUNDS(function, module, param, type, name)       \
  bounds = function(param);                                            \
  if (ZSTD_isError(bounds.error)) {                                    \
    ext_result = zstds_ext_get_error(ZSTD_getErrorCode(bounds.error)); \
    zstds_ext_raise_error(ext_result);                                 \
  }                                                                    \
                                                                       \
  rb_define_const(module, "MIN_" name, type##2NUM(bounds.lowerBound)); \
  rb_define_const(module, "MAX_" name, type##2NUM(bounds.upperBound));

#define EXPORT_COMPRESSOR_PARAM_BOUNDS(module, param, type, name) \
  EXPORT_PARAM_BOUNDS(ZSTD_cParam_getBounds, module, param, type, name);

#define EXPORT_DECOMPRESSOR_PARAM_BOUNDS(module, param, type, name) \
  EXPORT_PARAM_BOUNDS(ZSTD_dParam_getBounds, module, param, type, name);

void zstds_ext_option_exports(VALUE root_module)
{
  VALUE module = rb_define_module_under(root_module, "Option");

  zstds_ext_result_t ext_result;
  ZSTD_bounds        bounds;

  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_compressionLevel, INT, "COMPRESSION_LEVEL");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_windowLog, UINT, "WINDOW_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_hashLog, UINT, "HASH_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_chainLog, UINT, "CHAIN_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_searchLog, UINT, "SEARCH_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_minMatch, UINT, "MIN_MATCH");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_targetLength, UINT, "TARGET_LENGTH");

  VALUE strategies = rb_ary_new_from_args(
    9,
    ID2SYM(rb_intern("fast")),
    ID2SYM(rb_intern("dfast")),
    ID2SYM(rb_intern("greedy")),
    ID2SYM(rb_intern("lazy")),
    ID2SYM(rb_intern("lazy2")),
    ID2SYM(rb_intern("btlazy2")),
    ID2SYM(rb_intern("btopt")),
    ID2SYM(rb_intern("btultra")),
    ID2SYM(rb_intern("btultra2")));
  rb_define_const(module, "STRATEGIES", strategies);
  RB_GC_GUARD(strategies);

  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_ldmHashLog, UINT, "LDM_HASH_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_ldmMinMatch, UINT, "LDM_MIN_MATCH");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_ldmBucketSizeLog, UINT, "LDM_BUCKET_SIZE_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_ldmHashRateLog, UINT, "LDM_HASH_RATE_LOG");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_nbWorkers, UINT, "NB_WORKERS");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_jobSize, UINT, "JOB_SIZE");
  EXPORT_COMPRESSOR_PARAM_BOUNDS(module, ZSTD_c_overlapLog, UINT, "OVERLAP_LOG");

  EXPORT_DECOMPRESSOR_PARAM_BOUNDS(module, ZSTD_d_windowLogMax, UINT, "WINDOW_LOG_MAX");
}
