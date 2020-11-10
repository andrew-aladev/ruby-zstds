# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/stream/raw/decompressor"
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
        class Decompressor < Abstract
          Target = ZSTDS::Stream::Raw::Decompressor
          String = ZSTDS::String

          TEXTS                 = Common::TEXTS
          LARGE_TEXTS           = Common::LARGE_TEXTS
          PORTION_LENGTHS       = Common::PORTION_LENGTHS
          LARGE_PORTION_LENGTHS = Common::LARGE_PORTION_LENGTHS

          BUFFER_LENGTH_NAMES   = %i[destination_buffer_length].freeze
          BUFFER_LENGTH_MAPPING = { :destination_buffer_length => :destination_buffer_length }.freeze

          def test_invalid_initialize
            get_invalid_decompressor_options do |invalid_options|
              assert_raises ValidateError do
                Target.new invalid_options
              end
            end
          end

          def test_invalid_read
            decompressor = Target.new

            Validation::INVALID_STRINGS.each do |invalid_string|
              assert_raises ValidateError do
                decompressor.read invalid_string, &NOOP_PROC
              end
            end

            assert_raises ValidateError do
              decompressor.read ""
            end

            corrupted_compressed_text = String.compress("1111").reverse

            assert_raises DecompressorCorruptedSourceError do
              decompressor.read corrupted_compressed_text, &NOOP_PROC
            end

            decompressor.close(&NOOP_PROC)

            assert_raises UsedAfterCloseError do
              decompressor.read "", &NOOP_PROC
            end
          end

          def test_texts
            parallel_compressor_options do |compressor_options|
              TEXTS.each do |text|
                compressed_text = String.compress text, compressor_options

                PORTION_LENGTHS.each do |portion_length|
                  get_compatible_decompressor_options compressor_options do |decompressor_options|
                    decompressed_buffer = ::StringIO.new
                    decompressed_buffer.set_encoding ::Encoding::BINARY

                    writer       = proc { |portion| decompressed_buffer << portion }
                    decompressor = Target.new decompressor_options

                    begin
                      source                 = "".b
                      compressed_text_offset = 0
                      index                  = 0

                      loop do
                        portion = compressed_text.byteslice compressed_text_offset, portion_length
                        break if portion.nil?

                        compressed_text_offset += portion_length
                        source << portion

                        bytes_read = decompressor.read source, &writer
                        source     = source.byteslice bytes_read, source.bytesize - bytes_read

                        decompressor.flush(&writer) if index.even?
                        index += 1
                      end

                    ensure
                      refute decompressor.closed?
                      decompressor.close(&writer)
                      assert decompressor.closed?
                    end

                    decompressed_text = decompressed_buffer.string
                    decompressed_text.force_encoding text.encoding

                    assert_equal text, decompressed_text
                  end
                end
              end
            end
          end

          def test_large_texts
            options_generator = OCG.new(
              :text           => LARGE_TEXTS,
              :portion_length => LARGE_PORTION_LENGTHS
            )

            Common.parallel_options options_generator do |options|
              text           = options[:text]
              portion_length = options[:portion_length]

              compressed_text = String.compress text

              decompressed_buffer = ::StringIO.new
              decompressed_buffer.set_encoding ::Encoding::BINARY

              writer       = proc { |portion| decompressed_buffer << portion }
              decompressor = Target.new

              begin
                source                 = "".b
                compressed_text_offset = 0

                loop do
                  portion = compressed_text.byteslice compressed_text_offset, portion_length
                  break if portion.nil?

                  compressed_text_offset += portion_length
                  source << portion

                  bytes_read = decompressor.read source, &writer
                  source     = source.byteslice bytes_read, source.bytesize - bytes_read
                end
              ensure
                decompressor.close(&writer)
              end

              decompressed_text = decompressed_buffer.string
              decompressed_text.force_encoding text.encoding

              assert_equal text, decompressed_text
            end
          end

          # -----

          def get_invalid_decompressor_options(&block)
            Option.get_invalid_decompressor_options BUFFER_LENGTH_NAMES, &block
          end

          def parallel_compressor_options(&block)
            Common.parallel_options Option.get_compressor_options_generator(BUFFER_LENGTH_NAMES), &block
          end

          def get_compatible_decompressor_options(compressor_options, &block)
            Option.get_compatible_decompressor_options compressor_options, BUFFER_LENGTH_MAPPING, &block
          end
        end

        Minitest << Decompressor
      end
    end
  end
end
