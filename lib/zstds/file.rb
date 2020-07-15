# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "error"
require_relative "option"
require_relative "validation"

module ZSTDS
  module File
    BUFFER_LENGTH_NAMES = %i[source_buffer_length destination_buffer_length].freeze

    def self.compress(source, destination, options = {})
      Validation.validate_string source
      Validation.validate_string destination

      options = Option.get_compressor_options options, BUFFER_LENGTH_NAMES

      options[:pledged_size] = ::File.size source

      open_files(source, destination) do |source_io, destination_io|
        ZSTDS._native_compress_io source_io, destination_io, options
      end

      nil
    end

    def self.decompress(source, destination, options = {})
      Validation.validate_string source
      Validation.validate_string destination

      options = Option.get_decompressor_options options, BUFFER_LENGTH_NAMES

      open_files(source, destination) do |source_io, destination_io|
        ZSTDS._native_decompress_io source_io, destination_io, options
      end

      nil
    end

    private_class_method def self.open_files(source, destination, &_block)
      ::File.open source, "rb" do |source_io|
        ::File.open destination, "wb" do |destination_io|
          yield source_io, destination_io
        end
      end
    end
  end
end
