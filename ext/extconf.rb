# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "mkmf"

def require_header(name, types = [])
  abort "Can't find #{name} header" unless find_header name

  types.each do |type|
    abort "Can't find #{type} type in #{name} header" unless find_type type, nil, name
  end
end

require_header "zstd_errors.h", %w[ZSTD_ErrorCode]
require_header "zstd.h", [
  "ZSTD_CCtx *",
  "ZSTD_DCtx *",
  "ZSTD_CStream *",
  "ZSTD_DStream *",
  "ZSTD_strategy",
  "ZSTD_cParameter",
  "ZSTD_dParameter",
  "ZSTD_bounds",
  "ZSTD_inBuffer",
  "ZSTD_outBuffer"
]

def require_library(name, functions)
  functions.each do |function|
    abort "Can't find #{function} function in #{name} library" unless find_library name, function
  end
end

require_library(
  "zstd",
  %w[
    ZSTD_isError
    ZSTD_getErrorCode
    ZSTD_createCCtx
    ZSTD_createDCtx
    ZSTD_freeCCtx
    ZSTD_freeDCtx
    ZSTD_CCtx_setParameter
    ZSTD_DCtx_setParameter
    ZSTD_CCtx_setPledgedSrcSize
    ZSTD_cParam_getBounds
    ZSTD_dParam_getBounds
    ZSTD_CStreamInSize
    ZSTD_CStreamOutSize
    ZSTD_DStreamInSize
    ZSTD_DStreamOutSize
    ZSTD_compressStream
    ZSTD_flushStream
    ZSTD_endStream
    ZSTD_decompressStream
  ]
)

extension_name = "zstds_ext".freeze
dir_config extension_name

# rubocop:disable Style/GlobalVars
$srcs = %w[
  error
  main
  option
]
.map { |name| "src/#{extension_name}/#{name}.c" }
.freeze

$CFLAGS << " -Wno-declaration-after-statement"
$VPATH << "$(srcdir)/#{extension_name}:$(srcdir)/#{extension_name}/stream"
# rubocop:enable Style/GlobalVars

create_makefile extension_name
