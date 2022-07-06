# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/stream/writer"
require "zstds/stream/writer"
require "zstds/string"

require_relative "../minitest"
require_relative "../option"

module ZSTDS
  module Test
    module Stream
      class Writer < ADSP::Test::Stream::Writer
        Target = ZSTDS::Stream::Writer
        Option = Test::Option
        String = ZSTDS::String
      end

      Minitest << Writer
    end
  end
end
