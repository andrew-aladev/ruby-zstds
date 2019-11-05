# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/dictionary"
require "zstds/string"

require_relative "common"
require_relative "minitest"
require_relative "option"
require_relative "validation"

module ZSTDS
  module Test
    class Dictionary < Minitest::Unit::TestCase
      Target = ZSTDS::Dictionary
      String = ZSTDS::String

      TEXTS       = Common::TEXTS
      LARGE_TEXTS = Common::LARGE_TEXTS

      SAMPLES = Common.generate_texts(
        ::SecureRandom.random_bytes(1 << 10), # 1 KB
        ::SecureRandom.random_bytes(1 << 12), # 4 KB
        ::SecureRandom.random_bytes(1 << 14), # 16 KB
        ::SecureRandom.random_bytes(1 << 16), # 64 KB
        ::SecureRandom.random_bytes(1 << 18)  # 256 KB
      )
      .shuffle
      .freeze

      CAPACITIES = [
        0,
        1 << 12 # 4 KB
      ]
      .freeze

      BUFFER_LENGTH_NAMES   = %i[destination_buffer_length].freeze
      BUFFER_LENGTH_MAPPING = { :destination_buffer_length => :destination_buffer_length }.freeze

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
        dictionary = Target.new SAMPLES

        assert dictionary.id > 0
        assert dictionary.size > 0 # rubocop:disable Style/ZeroLengthPredicate

        compressed_text = String.compress TEXTS.sample, :dictionary => dictionary

        # Trying to decompress without dictionary.
        assert_raises ZSTDS::CorruptedDictionaryError do
          String.decompress compressed_text
        end
      end

      def test_texts
        CAPACITIES.each do |capacity|
          dictionary = Target.new SAMPLES, :capacity => capacity

          TEXTS.each do |text|
            get_compressor_options do |compressor_options|
              compressed_text = String.compress text, compressor_options.merge(:dictionary => dictionary)

              get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                decompressed_text = String.decompress compressed_text, decompressor_options.merge(:dictionary => dictionary)
                decompressed_text.force_encoding text.encoding

                assert_equal text, decompressed_text
              end
            end
          end
        end
      end

      def test_large_texts
        CAPACITIES.each do |capacity|
          dictionary = Target.new SAMPLES, :capacity => capacity

          LARGE_TEXTS.each do |text|
            compressed_text = String.compress text, :dictionary => dictionary

            decompressed_text = String.decompress compressed_text, :dictionary => dictionary
            decompressed_text.force_encoding text.encoding

            assert_equal text, decompressed_text
          end
        end
      end

      # -----

      def get_compressor_options(&block)
        Option.get_compressor_options BUFFER_LENGTH_NAMES, &block
      end

      def get_compatible_decompressor_options(compressor_options, &block)
        Option.get_compatible_decompressor_options compressor_options, BUFFER_LENGTH_MAPPING, &block
      end
    end

    Minitest << Dictionary
  end
end
