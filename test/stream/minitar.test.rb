# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/stream/minitar"
require "zstds/stream/reader"
require "zstds/stream/writer"

require_relative "../minitest"

module ZSTDS
  module Test
    module Stream
      class MinitarTest < ADSP::Test::Stream::MinitarTest
        Reader = ZSTDS::Stream::Reader
        Writer = ZSTDS::Stream::Writer
      end

      Minitest << MinitarTest
    end
  end
end
