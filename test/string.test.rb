# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/string"
require "zstds/string"

require_relative "minitest"
require_relative "option"

module ZSTDS
  module Test
    class String < ADSP::Test::String
      Target = ZSTDS::String
      Option = ZSTDS::Test::Option

      def test_invalid_text
        corrupted_compressed_text = Target.compress("1111").reverse

        assert_raises DecompressorCorruptedSourceError do
          Target.decompress corrupted_compressed_text
        end
      end
    end

    Minitest << String
  end
end
