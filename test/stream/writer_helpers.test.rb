# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "English"
require "stringio"
require "zstds/stream/writer"
require "zstds/string"

require_relative "../common"
require_relative "../minitest"
require_relative "../option"
require_relative "../validation"

module ZSTDS
  module Test
    module Stream
      class WriterHelpers < Minitest::Test
        Target = ZSTDS::Stream::Writer
        String = ZSTDS::String

        ARCHIVE_PATH          = Common::ARCHIVE_PATH
        TEXTS                 = Common::TEXTS
        LARGE_TEXTS           = Common::LARGE_TEXTS
        PORTION_LENGTHS       = Common::PORTION_LENGTHS
        LARGE_PORTION_LENGTHS = Common::LARGE_PORTION_LENGTHS

        BUFFER_LENGTH_NAMES   = %i[destination_buffer_length].freeze
        BUFFER_LENGTH_MAPPING = { :destination_buffer_length => :destination_buffer_length }.freeze

        def test_write
          TEXTS.each do |text|
            PORTION_LENGTHS.each do |portion_length|
              sources = get_sources text, portion_length

              get_compressor_options do |compressor_options|
                Target.open ARCHIVE_PATH, compressor_options do |instance|
                  sources.each { |current_source| instance << current_source }
                end

                compressed_text = ::File.read ARCHIVE_PATH

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  check_text text, compressed_text, decompressor_options
                end
              end
            end
          end
        end

        def test_print
          TEXTS.reject(&:empty?).each do |text|
            PORTION_LENGTHS.each do |portion_length|
              sources = get_sources text, portion_length

              field_separator  = " ".encode text.encoding
              record_separator = "\n".encode text.encoding

              target_text = "".encode text.encoding
              sources.each { |source| target_text << source + field_separator }
              target_text << record_separator

              get_compressor_options do |compressor_options|
                Target.open ARCHIVE_PATH, compressor_options do |instance|
                  keyword_args = { :field_separator => field_separator, :record_separator => record_separator }
                  instance.print(*sources, **keyword_args)
                end

                compressed_text = ::File.read ARCHIVE_PATH

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  check_text target_text, compressed_text, decompressor_options
                end
              end
            end
          end
        end

        def test_printf
          TEXTS.each do |text|
            PORTION_LENGTHS.each do |portion_length|
              sources = get_sources text, portion_length

              get_compressor_options do |compressor_options|
                Target.open ARCHIVE_PATH, compressor_options do |instance|
                  sources.each { |source| instance.printf "%s", source } # rubocop:disable Style/FormatStringToken
                end

                compressed_text = ::File.read ARCHIVE_PATH

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  check_text text, compressed_text, decompressor_options
                end
              end
            end
          end
        end

        def test_invalid_putc
          instance = target.new ::StringIO.new

          Validation::INVALID_CHARS.each do |invalid_char|
            assert_raises ValidateError do
              instance.putc invalid_char
            end
          end
        end

        def test_putc
          TEXTS.each do |text|
            get_compressor_options do |compressor_options|
              Target.open ARCHIVE_PATH, compressor_options do |instance|
                # Putc should process numbers and strings.
                text.chars.each.with_index do |char, index|
                  if index.even?
                    instance.putc char.ord, :encoding => text.encoding
                  else
                    instance.putc char
                  end
                end
              end

              compressed_text = ::File.read ARCHIVE_PATH

              get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                check_text text, compressed_text, decompressor_options
              end
            end
          end
        end

        def test_puts
          TEXTS.each do |text|
            PORTION_LENGTHS.each do |portion_length|
              newline = "\n".encode text.encoding

              sources = get_sources text, portion_length
              sources = sources.map do |source|
                source.delete_suffix! newline while source.end_with? newline
                source
              end

              target_text = "".encode text.encoding
              sources.each { |source| target_text << source + newline }

              get_compressor_options do |compressor_options|
                Target.open ARCHIVE_PATH, compressor_options do |instance|
                  # Puts should ignore additional newlines and process arrays.
                  args = sources.map.with_index do |source, index|
                    if index.even?
                      source + newline
                    else
                      [source]
                    end
                  end

                  instance.puts(*args)
                end

                compressed_text = ::File.read ARCHIVE_PATH

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  check_text target_text, compressed_text, decompressor_options
                end
              end
            end
          end
        end

        def test_invalid_open
          Validation::INVALID_STRINGS.each do |invalid_string|
            assert_raises ValidateError do
              Target.open(invalid_string) {}
            end
          end

          # Proc is required.
          assert_raises ValidateError do
            Target.open ARCHIVE_PATH
          end
        end

        def test_open
          TEXTS.each do |text|
            get_compressor_options do |compressor_options|
              Target.open(ARCHIVE_PATH, compressor_options) { |instance| instance.write text }

              compressed_text = ::File.read ARCHIVE_PATH

              get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                check_text text, compressed_text, decompressor_options
              end
            end
          end
        end

        def test_open_with_large_texts
          LARGE_TEXTS.each do |text|
            LARGE_PORTION_LENGTHS.each do |portion_length|
              sources = get_sources text, portion_length

              Target.open(ARCHIVE_PATH) do |instance|
                sources.each { |source| instance.write source }
              end

              compressed_text = ::File.read ARCHIVE_PATH

              check_text text, compressed_text, {}
            end
          end
        end

        # -----

        protected def get_sources(text, portion_length)
          sources = text
            .chars
            .each_slice(portion_length)
            .map(&:join)

          return [""] if sources.empty?

          sources
        end

        protected def check_text(text, compressed_text, decompressor_options)
          decompressed_text = String.decompress compressed_text, decompressor_options
          decompressed_text.force_encoding text.encoding

          assert_equal text, decompressed_text
        end

        def get_compressor_options(&block)
          Option.get_compressor_options BUFFER_LENGTH_NAMES, &block
        end

        def get_compatible_decompressor_options(compressor_options, &block)
          Option.get_compatible_decompressor_options compressor_options, BUFFER_LENGTH_MAPPING, &block
        end

        protected def target
          self.class::Target
        end
      end

      Minitest << WriterHelpers
    end
  end
end
