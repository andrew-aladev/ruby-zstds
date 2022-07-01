# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/stream/reader"

require_relative "raw/decompressor"

module ZSTDS
  module Stream
    # ZSTDS::Stream::Reader class.
    class Reader < ADSP::Stream::Reader
      # Current raw stream class.
      RawDecompressor = Raw::Decompressor
    end
  end
end
