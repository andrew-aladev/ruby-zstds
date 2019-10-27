# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/string"

require_relative "common"
require_relative "minitest"
require_relative "option"
require_relative "validation"

module ZSTDS
  module Test
    class String < Minitest::Unit::TestCase
      Target = ZSTDS::String

      TEXTS       = Common::TEXTS
      LARGE_TEXTS = Common::LARGE_TEXTS

      BUFFER_LENGTH_NAMES   = %i[destination_buffer_length].freeze
      BUFFER_LENGTH_MAPPING = { :destination_buffer_length => :destination_buffer_length }.freeze

      # def test_invalid_arguments
      #   Validation::INVALID_STRINGS.each do |invalid_string|
      #     assert_raises ValidateError do
      #       Target.compress invalid_string
      #     end
      #
      #     assert_raises ValidateError do
      #       Target.decompress invalid_string
      #     end
      #   end
      #
      #   INVALID_COMPRESSOR_OPTIONS.each do |invalid_options|
      #     assert_raises ValidateError do
      #       Target.compress "", invalid_options
      #     end
      #   end
      #
      #   INVALID_DECOMPRESSOR_OPTIONS.each do |invalid_options|
      #     assert_raises ValidateError do
      #       Target.decompress "", invalid_options
      #     end
      #   end
      # end

      # def test_invalid_text
      #   corrupted_compressed_text = Target.compress("1111").reverse
      #
      #   assert_raises DecompressorCorruptedSourceError do
      #     Target.decompress corrupted_compressed_text
      #   end
      # end

      # def test_texts
      #   TEXTS.each do |text|
      #     COMPRESSOR_OPTION_COMBINATIONS.each do |compressor_options|
      #       compressed_text = Target.compress text, compressor_options
      #
      #       get_compatible_decompressor_options(compressor_options) do |decompressor_options|
      #         decompressed_text = Target.decompress compressed_text, decompressor_options
      #         decompressed_text.force_encoding text.encoding
      #
      #         assert_equal text, decompressed_text
      #       end
      #     end
      #   end
      # end

      # def test_large_texts
      #   LARGE_TEXTS.each do |text|
      #     compressed_text = Target.compress text
      #
      #     decompressed_text = Target.decompress compressed_text
      #     decompressed_text.force_encoding text.encoding
      #
      #     assert_equal text, decompressed_text
      #   end
      # end

      # -----

      def get_compressor_options(&block)
        Option.get_compressor_options BUFFER_LENGTH_NAMES, &block
      end

      def get_compatible_decompressor_options(compressor_options, &block)
        Option.get_compatible_decompressor_options compressor_options, BUFFER_LENGTH_MAPPING, &block
      end
    end

    Minitest << String
  end
end
