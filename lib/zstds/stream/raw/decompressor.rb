# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/stream/raw/decompressor"
require "zstds_ext"

require_relative "../../option"

module ZSTDS
  module Stream
    module Raw
      # ZSTDS::Stream::Raw::Decompressor class.
      class Decompressor < ADSP::Stream::Raw::Decompressor
        # Current native decompressor class.
        NativeDecompressor = Stream::NativeDecompressor

        # Current option class.
        Option = ZSTDS::Option
      end
    end
  end
end
