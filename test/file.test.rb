# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require_relative "helper"

require "zstds/file"

require_relative "common"
require_relative "minitest"
require_relative "option"
require_relative "validation"

module ZSTDS
  module Test
    class File < Minitest::Test
      Target = ZSTDS::File

      SOURCE_PATH  = Common::SOURCE_PATH
      ARCHIVE_PATH = Common::ARCHIVE_PATH
      TEXTS        = Common::TEXTS
      LARGE_TEXTS  = Common::LARGE_TEXTS

      BUFFER_LENGTH_NAMES   = %i[source_buffer_length destination_buffer_length].freeze
      BUFFER_LENGTH_MAPPING = {
        :source_buffer_length      => :destination_buffer_length,
        :destination_buffer_length => :source_buffer_length
      }
      .freeze

      def test_invalid_arguments
        Validation::INVALID_STRINGS.each do |invalid_path|
          assert_raises ValidateError do
            Target.compress invalid_path, ARCHIVE_PATH
          end

          assert_raises ValidateError do
            Target.compress SOURCE_PATH, invalid_path
          end

          assert_raises ValidateError do
            Target.decompress invalid_path, SOURCE_PATH
          end

          assert_raises ValidateError do
            Target.decompress ARCHIVE_PATH, invalid_path
          end
        end

        get_invalid_compressor_options do |invalid_options|
          assert_raises ValidateError do
            Target.compress SOURCE_PATH, ARCHIVE_PATH, invalid_options
          end
        end

        get_invalid_decompressor_options do |invalid_options|
          assert_raises ValidateError do
            Target.decompress ARCHIVE_PATH, SOURCE_PATH, invalid_options
          end
        end
      end

      def test_texts
        TEXTS.each do |text|
          ::File.write SOURCE_PATH, text

          get_compressor_options do |compressor_options|
            Target.compress SOURCE_PATH, ARCHIVE_PATH, compressor_options

            get_compatible_decompressor_options(compressor_options) do |decompressor_options|
              Target.decompress ARCHIVE_PATH, SOURCE_PATH, decompressor_options

              decompressed_text = ::File.read SOURCE_PATH
              decompressed_text.force_encoding text.encoding

              assert_equal text, decompressed_text
            end
          end
        end
      end

      def test_large_texts
        LARGE_TEXTS.each do |text|
          ::File.write SOURCE_PATH, text

          Target.compress SOURCE_PATH, ARCHIVE_PATH
          Target.decompress ARCHIVE_PATH, SOURCE_PATH

          decompressed_text = ::File.read SOURCE_PATH
          decompressed_text.force_encoding text.encoding

          assert_equal text, decompressed_text
        end
      end

      # -----

      def get_invalid_compressor_options(&block)
        Option.get_invalid_compressor_options BUFFER_LENGTH_NAMES, &block
      end

      def get_invalid_decompressor_options(&block)
        Option.get_invalid_decompressor_options BUFFER_LENGTH_NAMES, &block
      end

      def get_compressor_options(&block)
        Option.get_compressor_options BUFFER_LENGTH_NAMES, &block
      end

      def get_compatible_decompressor_options(compressor_options, &block)
        Option.get_compatible_decompressor_options compressor_options, BUFFER_LENGTH_MAPPING, &block
      end
    end

    Minitest << File
  end
end
