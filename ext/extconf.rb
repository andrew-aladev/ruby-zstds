# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "mkmf"

have_func "rb_thread_call_without_gvl", "ruby/thread.h"

# Old zstd versions has bug: underlinking against pthreads.
# https://bugs.gentoo.org/713940
$LDFLAGS << " -pthread" # rubocop:disable Style/GlobalVars

def require_header(name, types = [])
  abort "Can't find #{name} header" unless find_header name

  types.each do |type|
    abort "Can't find #{type} type in #{name} header" unless find_type type, nil, name
  end
end

require_header "zstd_errors.h", %w[
  ZSTD_ErrorCode
]
require_header "zstd.h", [
  "ZSTD_CCtx *",
  "ZSTD_DCtx *",
  "ZSTD_strategy",
  "ZSTD_bounds",
  "ZSTD_inBuffer",
  "ZSTD_outBuffer"
]
require_header "zdict.h"

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
    ZSTD_compressStream2
    ZSTD_decompressStream
    ZDICT_getDictID
    ZDICT_trainFromBuffer
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

if ENV["CI"] || ENV["COVERAGE"]
  $CFLAGS << " --coverage"
  $LDFLAGS << " --coverage"
end

$CFLAGS << " -Wno-declaration-after-statement"

$VPATH << "$(srcdir)/#{extension_name}:$(srcdir)/#{extension_name}/stream"
# rubocop:enable Style/GlobalVars

create_makefile extension_name
