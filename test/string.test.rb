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

      def test_texts
        get_compressor_options do |compressor_options|
          # pp compressor_options
        end

        TEXTS.each do |text|
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

    Minitest << String
  end
end
