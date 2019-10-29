# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "option"
require_relative "validation"

module ZSTDS
  module String
    BUFFER_LENGTH_NAMES = %i[destination_buffer_length].freeze

    def self.compress(source, options = {})
      Validation.validate_string source

      options = Option.get_compressor_options options, BUFFER_LENGTH_NAMES

      options[:pledged_size] = source.bytesize

      ZSTDS._native_compress_string source, options
    end

    def self.decompress(source, options = {})
      Validation.validate_string source

      options = Option.get_decompressor_options options, BUFFER_LENGTH_NAMES

      ZSTDS._native_decompress_string source, options
    end
  end
end
