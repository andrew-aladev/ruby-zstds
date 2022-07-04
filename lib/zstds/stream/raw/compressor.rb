# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/stream/raw/compressor"
require "zstds_ext"

require_relative "../../option"
require_relative "../../validation"

module ZSTDS
  module Stream
    module Raw
      # ZSTDS::Stream::Raw::Compressor class.
      class Compressor < ADSP::Stream::Raw::Compressor
        # Current native compressor class.
        NativeCompressor = Stream::NativeCompressor

        # Current option class.
        Option = ZSTDS::Option

        # Initializes compressor.
        # Option: +:destination_buffer_length+ destination buffer length.
        # Option: +:pledged_size+ source bytesize.
        def initialize(options = {})
          options = Option.get_compressor_options options, BUFFER_LENGTH_NAMES

          pledged_size = options[:pledged_size]
          Validation.validate_not_negative_integer pledged_size unless pledged_size.nil?

          super options
        end
      end
    end
  end
end
