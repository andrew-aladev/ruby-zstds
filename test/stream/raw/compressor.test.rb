# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/stream/raw/compressor"
require "zstds/string"

require_relative "abstract"
require_relative "../../common"
require_relative "../../minitest"
require_relative "../../option"
require_relative "../../validation"

module ZSTDS
  module Test
    module Stream
      module Raw
        class Compressor < Abstract
          Target = ZSTDS::Stream::Raw::Compressor
          String = ZSTDS::String

          TEXTS                 = Common::TEXTS
          LARGE_TEXTS           = Common::LARGE_TEXTS
          PORTION_LENGTHS       = Common::PORTION_LENGTHS
          LARGE_PORTION_LENGTHS = Common::LARGE_PORTION_LENGTHS

          BUFFER_LENGTH_NAMES   = %i[destination_buffer_length].freeze
          BUFFER_LENGTH_MAPPING = { :destination_buffer_length => :destination_buffer_length }.freeze

          def test_invalid_initialize
            get_invalid_compressor_options do |invalid_options|
              assert_raises ValidateError do
                Target.new invalid_options
              end
            end

            (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
              assert_raises ValidateError do
                Target.new :pledged_size => invalid_integer
              end
            end
          end

          def test_invalid_write
            compressor = Target.new

            Validation::INVALID_STRINGS.each do |invalid_string|
              assert_raises ValidateError do
                compressor.write invalid_string, &NOOP_PROC
              end
            end

            assert_raises ValidateError do
              compressor.write ""
            end

            compressor.close(&NOOP_PROC)

            assert_raises UsedAfterCloseError do
              compressor.write "", &NOOP_PROC
            end
          end

          def test_texts
            contexts = OCG.new(
              :text           => TEXTS,
              :portion_length => PORTION_LENGTHS
            )
            .to_a

            Common.parallel_each contexts do |context|
              text           = context[:text]
              portion_length = context[:portion_length]

              get_compressor_options do |compressor_options|
                compressed_buffer = ::StringIO.new
                compressed_buffer.set_encoding ::Encoding::BINARY

                writer = proc { |portion| compressed_buffer << portion }

                compressor = Target.new compressor_options.merge(:pledged_size => text.bytesize)

                begin
                  source      = "".b
                  text_offset = 0
                  index       = 0

                  loop do
                    portion = text.byteslice text_offset, portion_length
                    break if portion.nil?

                    text_offset += portion_length
                    source << portion

                    bytes_written = compressor.write source, &writer
                    source        = source.byteslice bytes_written, source.bytesize - bytes_written

                    compressor.flush(&writer) if index.even?
                    index += 1
                  end

                ensure
                  refute compressor.closed?
                  compressor.close(&writer)
                  assert compressor.closed?
                end

                compressed_text = compressed_buffer.string

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  decompressed_text = String.decompress compressed_text, decompressor_options
                  decompressed_text.force_encoding text.encoding

                  assert_equal text, decompressed_text
                end
              end
            end
          end

          def test_large_texts
            contexts = OCG.new(
              :text           => LARGE_TEXTS,
              :portion_length => LARGE_PORTION_LENGTHS
            )
            .to_a

            Common.parallel_each contexts do |context|
              text           = context[:text]
              portion_length = context[:portion_length]

              compressed_buffer = ::StringIO.new
              compressed_buffer.set_encoding ::Encoding::BINARY

              writer = proc { |portion| compressed_buffer << portion }

              compressor = Target.new

              begin
                source      = "".b
                text_offset = 0

                loop do
                  portion = text.byteslice text_offset, portion_length
                  break if portion.nil?

                  text_offset += portion_length
                  source << portion

                  bytes_written = compressor.write source, &writer
                  source        = source.byteslice bytes_written, source.bytesize - bytes_written
                end
              ensure
                compressor.close(&writer)
              end

              compressed_text = compressed_buffer.string

              decompressed_text = String.decompress compressed_text
              decompressed_text.force_encoding text.encoding

              assert_equal text, decompressed_text
            end
          end

          # -----

          def get_invalid_compressor_options(&block)
            Option.get_invalid_compressor_options BUFFER_LENGTH_NAMES, &block
          end

          def get_compressor_options(&block)
            Option.get_compressor_options BUFFER_LENGTH_NAMES, &block
          end

          def get_compatible_decompressor_options(compressor_options, &block)
            Option.get_compatible_decompressor_options compressor_options, BUFFER_LENGTH_MAPPING, &block
          end
        end

        Minitest << Compressor
      end
    end
  end
end
