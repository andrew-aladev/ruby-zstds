# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/stream/reader_helpers"
require "zstds/stream/reader"
require "zstds/string"

require_relative "../minitest"
require_relative "../option"

module ZSTDS
  module Test
    module Stream
      class ReaderHelpers < ADSP::Test::Stream::ReaderHelpers
        Target = ZSTDS::Stream::Reader
        Option = Test::Option
        String = ZSTDS::String
      end

      Minitest << ReaderHelpers
    end
  end
end
