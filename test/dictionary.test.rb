# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/dictionary"
require "zstds/string"

require_relative "common"
require_relative "minitest"
require_relative "validation"

module ZSTDS
  module Test
    class Dictionary < Minitest::Test
      Target = ZSTDS::Dictionary
      String = ZSTDS::String

      TEXTS              = Common::TEXTS
      DICTIONARY_SAMPLES = Common::DICTIONARY_SAMPLES

      DICTIONARY_CAPACITIES = [
        0,
        1 << 12 # 4 KB
      ]
      .freeze

      def test_invalid_arguments
        Validation::INVALID_ARRAYS.each do |invalid_samples|
          assert_raises ValidateError do
            Target.new invalid_samples
          end
        end

        Validation::INVALID_STRINGS.each do |invalid_sample|
          assert_raises ValidateError do
            Target.new [invalid_sample]
          end
        end

        assert_raises ValidateError do
          Target.new [""]
        end

        Validation::INVALID_NOT_NEGATIVE_INTEGERS.each do |invalid_capacity|
          assert_raises ValidateError do
            Target.new ["123"], :capacity => invalid_capacity
          end
        end
      end

      def test_basic
        DICTIONARY_CAPACITIES.each do |dictionary_capacity|
          dictionary = Target.new DICTIONARY_SAMPLES, :capacity => dictionary_capacity

          assert dictionary.id > 0
          assert dictionary.size > 0 # rubocop:disable Style/ZeroLengthPredicate

          compressed_text = String.compress TEXTS.sample, :dictionary => dictionary

          # Trying to decompress without dictionary.
          assert_raises ZSTDS::CorruptedDictionaryError do
            String.decompress compressed_text
          end
        end
      end
    end

    Minitest << Dictionary
  end
end
