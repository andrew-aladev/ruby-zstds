# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "mkmf"

have_func "rb_thread_call_without_gvl", "ruby/thread.h"

# Old zstd versions has bug: underlinking against pthreads.
# https://bugs.gentoo.org/713940
$LDFLAGS << " -pthread" # rubocop:disable Style/GlobalVars

def require_header(name, constants: [], macroses: [], types: [])
  abort "Can't find #{name} header" unless find_header name

  constants.each do |constant|
    abort "Can't find #{constant} constant in #{name} header" unless have_const constant, name
  end

  macroses.each do |macro|
    abort "Can't find #{macro} macro in #{name} header" unless have_macro macro, name
  end

  types.each do |type|
    abort "Can't find #{type} type in #{name} header" unless find_type type, nil, name
  end
end

require_header "zdict.h"
require_header(
  "zstd.h",
  :constants => %w[
    ZSTD_btlazy2
    ZSTD_btopt
    ZSTD_btultra
    ZSTD_btultra2
    ZSTD_c_chainLog
    ZSTD_c_checksumFlag
    ZSTD_c_compressionLevel
    ZSTD_c_contentSizeFlag
    ZSTD_c_dictIDFlag
    ZSTD_c_enableLongDistanceMatching
    ZSTD_c_hashLog
    ZSTD_c_jobSize
    ZSTD_c_ldmBucketSizeLog
    ZSTD_c_ldmHashLog
    ZSTD_c_ldmHashRateLog
    ZSTD_c_ldmMinMatch
    ZSTD_c_minMatch
    ZSTD_c_nbWorkers
    ZSTD_c_overlapLog
    ZSTD_c_searchLog
    ZSTD_c_strategy
    ZSTD_c_targetLength
    ZSTD_c_windowLog
    ZSTD_dfast
    ZSTD_d_windowLogMax
    ZSTD_e_continue
    ZSTD_e_end
    ZSTD_e_flush
    ZSTD_fast
    ZSTD_greedy
    ZSTD_lazy
    ZSTD_lazy2
  ],
  :macroses  => %w[ZSTD_VERSION_STRING],
  :types     => [
    "ZSTD_bounds",
    "ZSTD_CCtx *",
    "ZSTD_DCtx *",
    "ZSTD_inBuffer",
    "ZSTD_outBuffer",
    "ZSTD_strategy"
  ]
)

require_header(
  "zstd_errors.h",
  :constants => %w[
    ZSTD_error_checksum_wrong
    ZSTD_error_corruption_detected
    ZSTD_error_dictionaryCreation_failed
    ZSTD_error_dictionary_corrupted
    ZSTD_error_dictionary_wrong
    ZSTD_error_dstBuffer_null
    ZSTD_error_dstSize_tooSmall
    ZSTD_error_frameParameter_unsupported
    ZSTD_error_frameParameter_windowTooLarge
    ZSTD_error_init_missing
    ZSTD_error_maxSymbolValue_tooLarge
    ZSTD_error_maxSymbolValue_tooSmall
    ZSTD_error_memory_allocation
    ZSTD_error_parameter_outOfBound
    ZSTD_error_parameter_unsupported
    ZSTD_error_prefix_unknown
    ZSTD_error_srcSize_wrong
    ZSTD_error_stage_wrong
    ZSTD_error_tableLog_tooLarge
    ZSTD_error_version_unsupported
    ZSTD_error_workSpace_tooSmall
  ],
  :types     => %w[ZSTD_ErrorCode]
)

def require_library(name, functions)
  functions.each do |function|
    abort "Can't find #{function} function in #{name} library" unless find_library name, function
  end
end

# rubocop:disable Style/GlobalVars
if find_library "zstd", "ZDICT_getDictHeaderSize"
  $defs.push "-DHAVE_ZDICT_HEADER_SIZE"
end

zdict_has_params   = find_type "ZDICT_params_t", nil, "zdict.h"
zdict_has_finalize = find_library "zstd", "ZDICT_finalizeDictionary"

if zdict_has_params && zdict_has_finalize
  $defs.push "-DHAVE_ZDICT_FINALIZE"
end
# rubocop:enable Style/GlobalVars

require_library(
  "zstd",
  %w[
    ZDICT_getDictID
    ZDICT_isError
    ZDICT_trainFromBuffer
    ZSTD_CCtx_loadDictionary
    ZSTD_CCtx_setParameter
    ZSTD_CCtx_setPledgedSrcSize
    ZSTD_CStreamInSize
    ZSTD_CStreamOutSize
    ZSTD_compressStream2
    ZSTD_cParam_getBounds
    ZSTD_createCCtx
    ZSTD_createDCtx
    ZSTD_DCtx_setParameter
    ZSTD_DCtx_loadDictionary
    ZSTD_DStreamInSize
    ZSTD_DStreamOutSize
    ZSTD_decompressStream
    ZSTD_dParam_getBounds
    ZSTD_freeCCtx
    ZSTD_freeDCtx
    ZSTD_getErrorCode
    ZSTD_isError
  ]
)

extension_name = "zstds_ext".freeze
dir_config extension_name

# rubocop:disable Style/GlobalVars
$srcs = %w[
  stream/compressor
  stream/decompressor
  buffer
  dictionary
  error
  io
  main
  option
  string
]
.map { |name| "src/#{extension_name}/#{name}.c" }
.freeze

# Removing library duplicates.
$libs = $libs.split(%r{\s})
  .reject(&:empty?)
  .sort
  .uniq
  .join " "

if ENV["CI"]
  $CFLAGS << " --coverage"
  $LDFLAGS << " --coverage"
end

$CFLAGS << " -Wno-declaration-after-statement"

$VPATH << "$(srcdir)/#{extension_name}:$(srcdir)/#{extension_name}/stream"
# rubocop:enable Style/GlobalVars

create_makefile extension_name
