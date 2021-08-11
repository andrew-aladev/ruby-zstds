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

      TEXTS   = Common::TEXTS
      SAMPLES = Common::DICTIONARY_SAMPLES

      CAPACITIES = [
        0,
        1 << 12 # 4 KB
      ]
      .freeze

      def test_invalid_initialize
        (Validation::INVALID_STRINGS + [""]).each do |invalid_buffer|
          assert_raises ValidateError do
            Target.new invalid_buffer
          end
        end
      end

      def test_invalid_train
        Validation::INVALID_ARRAYS.each do |invalid_samples|
          assert_raises ValidateError do
            Target.train invalid_samples
          end
        end

        (Validation::INVALID_STRINGS + [""]).each do |invalid_sample|
          assert_raises ValidateError do
            Target.train [invalid_sample]
          end
        end

        Validation::INVALID_BOOLS.each do |invalid_bool|
          assert_raises ValidateError do
            Target.train ["123"], :gvl => invalid_bool
          end
        end

        Validation::INVALID_NOT_NEGATIVE_INTEGERS.each do |invalid_capacity|
          assert_raises ValidateError do
            Target.train ["123"], :capacity => invalid_capacity
          end
        end
      end

      def test_basic
        Common.parallel CAPACITIES do |capacity|
          dictionary = Target.train SAMPLES, :capacity => capacity

          assert dictionary.id.positive?
          refute_nil dictionary.buffer
          refute_empty dictionary.buffer

          dictionary_copy = Target.new dictionary.buffer

          assert_equal dictionary.id, dictionary_copy.id
          assert_equal dictionary.buffer, dictionary_copy.buffer

          text            = TEXTS.sample
          compressed_text = String.compress text, :dictionary => dictionary

          decompressed_text = String.decompress compressed_text, :dictionary => dictionary
          decompressed_text.force_encoding text.encoding

          assert_equal text, decompressed_text

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
