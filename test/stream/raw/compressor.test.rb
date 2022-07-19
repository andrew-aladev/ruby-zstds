# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/stream/raw/compressor"
require "zstds/stream/raw/compressor"
require "zstds/string"

require_relative "../../minitest"
require_relative "../../option"

module ZSTDS
  module Test
    module Stream
      module Raw
        class Compressor < ADSP::Test::Stream::Raw::Compressor
          Target = ZSTDS::Stream::Raw::Compressor
          Option = Test::Option
          String = ZSTDS::String
        end

        Minitest << Compressor
      end
    end
  end
end
