# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "ocg"
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

      INVALID_COMPRESSION_LEVELS = (
        Validation::INVALID_INTEGERS +
        [
          ZSTDS::Option::MIN_COMPRESSION_LEVEL - 1,
          ZSTDS::Option::MAX_COMPRESSION_LEVEL + 1
        ]
      )
      .freeze

      TEXTS    = Common::TEXTS
      CONTENTS = Common::DICTIONARY_CONTENTS
      SAMPLES  = Common::DICTIONARY_SAMPLES

      CAPACITIES = MAX_SIZES = [
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

      def test_invalid_finalize
        Validation::INVALID_ARRAYS.each do |invalid_samples|
          assert_raises ValidateError do
            Target.finalize "123", invalid_samples
          end
        end

        (Validation::INVALID_STRINGS + [""]).each do |invalid_text|
          assert_raises ValidateError do
            Target.finalize invalid_text, ["123"]
          end

          assert_raises ValidateError do
            Target.finalize "123", [invalid_text]
          end
        end

        Validation::INVALID_BOOLS.each do |invalid_bool|
          assert_raises ValidateError do
            Target.finalize "123", ["123"], :gvl => invalid_bool
          end
        end

        Validation::INVALID_INTEGERS.each do |invalid_integer|
          assert_raises ValidateError do
            Target.finalize "123", ["123"], :max_size => invalid_integer
          end

          assert_raises ValidateError do
            Target.finalize "123", ["123"], :dictionary_options => {
              :notification_level => invalid_integer
            }
          end

          assert_raises ValidateError do
            Target.finalize "123", ["123"], :dictionary_options => {
              :dictionary_id => invalid_integer
            }
          end
        end

        INVALID_COMPRESSION_LEVELS.each do |invalid_compression_level|
          assert_raises ValidateError do
            Target.finalize "123", ["123"], :dictionary_options => {
              :compression_level => invalid_compression_level
            }
          end
        end

      rescue NotImplementedError
        # Finalize may not be implemented.
      end

      def process_dictionary(dictionary)
        assert_predicate dictionary.id, :positive?

        begin
          assert_predicate dictionary.header_size, :positive?
        rescue NotImplementedError
          # Header size may not be implemented.
        end

        refute_nil dictionary.buffer
        refute_empty dictionary.buffer

        dictionary_copy = Target.new dictionary.buffer

        assert_equal dictionary.id, dictionary_copy.id

        begin
          assert_equal dictionary.header_size, dictionary_copy.header_size
        rescue NotImplementedError
          # Header size may not be implemented.
        end

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

      def test_train
        Common.parallel CAPACITIES do |capacity|
          dictionary = Target.train SAMPLES, :capacity => capacity
          process_dictionary dictionary
        end
      end

      def test_finalize
        options_generator = OCG.new(
          :content  => CONTENTS,
          :max_size => MAX_SIZES
        )

        Common.parallel_options options_generator do |options|
          content  = options[:content]
          max_size = options[:max_size]

          dictionary = Target.finalize content, SAMPLES, :max_size => max_size
          process_dictionary dictionary

          dictionary = Target.finalize(
            content,
            SAMPLES,
            :max_size           => max_size,
            :dictionary_options => {
              :compression_level  => ZSTDS::Option::MAX_COMPRESSION_LEVEL,
              :notification_level => 1,
              :dictionary_id      => 2
            }
          )
          process_dictionary dictionary
        end
      end
    end

    Minitest << Dictionary
  end
end
