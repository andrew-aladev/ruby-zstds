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

    # Compresses data from +source+ file path to +destination+ file path.
    # Option: +:source_buffer_length+ source buffer length.
    # Option: +:destination_buffer_length+ destination buffer length.
    # Option: +:pledged_size+ source bytesize.
    def self.compress(source, destination, options = {})
      Validation.validate_string source

      options = Option.get_compressor_options options, BUFFER_LENGTH_NAMES

      options[:pledged_size] = ::File.size source

      super source, destination, options
    end

    # Bypass native compress.
    def self.native_compress_io(*args)
      ZSTDS._native_compress_io(*args)
    end

    # Bypass native decompress.
    def self.native_decompress_io(*args)
      ZSTDS._native_decompress_io(*args)
    end
  end
end
