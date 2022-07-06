# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/stream/reader"
require "zstds/stream/reader"
require "zstds/string"
require "stringio"

require_relative "../minitest"
require_relative "../option"

module ZSTDS
  module Test
    module Stream
      class Reader < ADSP::Test::Stream::Reader
        Target = ZSTDS::Stream::Reader
        Option = Test::Option
        String = ZSTDS::String

        def test_invalid_read
          super

          corrupted_compressed_text = String.compress("1111").reverse
          instance                  = target.new ::StringIO.new(corrupted_compressed_text)

          assert_raises DecompressorCorruptedSourceError do
            instance.read
          end
        end

        def test_invalid_readpartial_and_read_nonblock
          super

          corrupted_compressed_text = String.compress("1111").reverse

          instance = target.new ::StringIO.new(corrupted_compressed_text)

          assert_raises DecompressorCorruptedSourceError do
            instance.readpartial 1
          end

          instance = target.new ::StringIO.new(corrupted_compressed_text)

          assert_raises DecompressorCorruptedSourceError do
            instance.read_nonblock 1
          end
        end
      end

      Minitest << Reader
    end
  end
end
