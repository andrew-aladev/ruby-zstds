# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/string"
require "zstds_ext"

require_relative "option"
require_relative "validation"

module ZSTDS
  # ZSTDS::String class.
  class String < ADSP::String
    # Current option class.
    Option = ZSTDS::Option

    def self.compress(source, options = {})
      Validation.validate_string source

      options = Option.get_compressor_options options, BUFFER_LENGTH_NAMES

      options[:pledged_size] = source.bytesize

      super source, options
    end

    def self.native_compress_string(*args)
      ZSTDS._native_compress_string(*args)
    end

    def self.native_decompress_string(*args)
      ZSTDS._native_decompress_string(*args)
    end
  end
end
