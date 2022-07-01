# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/file"
require "zstds_ext"

require_relative "option"
require_relative "validation"

module ZSTDS
  # ZSTDS::File class.
  class File < ADSP::File
    # Current option class.
    Option = ZSTDS::Option

    def self.compress(source, destination, options = {})
      Validation.validate_string source

      options = Option.get_compressor_options options, BUFFER_LENGTH_NAMES

      options[:pledged_size] = ::File.size source

      super source, destination, options
    end

    def self.native_compress_io(*args)
      ZSTDS._native_compress_io(*args)
    end

    def self.native_decompress_io(*args)
      ZSTDS._native_decompress_io(*args)
    end
  end
end
