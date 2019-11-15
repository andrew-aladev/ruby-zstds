# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "socket"
require "zstds/stream/reader"
require "zstds/string"

require_relative "abstract"
require_relative "../common"
require_relative "../minitest"
require_relative "../option"
require_relative "../validation"

module ZSTDS
  module Test
    module Stream
      class Reader < Abstract
        Target = ZSTDS::Stream::Reader
        String = ZSTDS::String

        ARCHIVE_PATH      = Common::ARCHIVE_PATH
        PORT              = Common::PORT
        ENCODINGS         = Common::ENCODINGS
        TRANSCODE_OPTIONS = Common::TRANSCODE_OPTIONS
        TEXTS             = Common::TEXTS
        PORTION_LENGTHS   = Common::PORTION_LENGTHS

        BUFFER_LENGTH_NAMES   = %i[source_buffer_length destination_buffer_length].freeze
        BUFFER_LENGTH_MAPPING = {
          :source_buffer_length      => :destination_buffer_length,
          :destination_buffer_length => :source_buffer_length
        }
        .freeze

        def test_invalid_initialize
          get_invalid_decompressor_options do |invalid_options|
            assert_raises ValidateError do
              target.new ::STDIN, invalid_options
            end
          end

          super
        end

        # -- synchronous --

        def test_invalid_read
          instance = target.new ::STDIN

          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
            assert_raises ValidateError do
              instance.read invalid_integer
            end
          end

          (Validation::INVALID_STRINGS - [nil]).each do |invalid_string|
            assert_raises ValidateError do
              instance.read nil, invalid_string
            end
          end

          corrupted_compressed_text = String.compress("1111").reverse
          ::File.write ARCHIVE_PATH, corrupted_compressed_text

          ::File.open ARCHIVE_PATH, "rb" do |file|
            instance = target.new file

            assert_raises DecompressorCorruptedSourceError do
              instance.read
            end
          end
        end

        def test_read
          TEXTS.each do |text|
            [true, false].each do |with_buffer|
              get_compressor_options do |compressor_options|
                prev_result = "".b

                PORTION_LENGTHS.each do |portion_length|
                  write_archive text, compressor_options

                  get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                    decompressed_text = "".b

                    ::File.open ARCHIVE_PATH, "rb" do |file|
                      instance = target.new file, decompressor_options

                      begin
                        result = instance.read 0
                        assert_equal result, ""

                        loop do
                          result =
                            if with_buffer
                              instance.read portion_length, prev_result
                            else
                              instance.read portion_length
                            end

                          break if result.nil?

                          assert_equal result, prev_result if with_buffer
                          decompressed_text << result
                        end

                        assert_equal instance.pos, decompressed_text.bytesize
                        assert_equal instance.pos, instance.tell
                      ensure
                        refute instance.closed?
                        instance.close
                        assert instance.closed?
                      end
                    end

                    decompressed_text.force_encoding text.encoding
                    assert_equal text, decompressed_text
                  end
                end

                write_archive text, compressor_options

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  decompressed_text = nil

                  ::File.open ARCHIVE_PATH, "rb" do |file|
                    instance = target.new file, decompressor_options

                    begin
                      if with_buffer
                        decompressed_text = instance.read nil, prev_result
                        assert_equal decompressed_text, prev_result
                      else
                        decompressed_text = instance.read
                      end

                      assert_equal instance.pos, decompressed_text.bytesize
                      assert_equal instance.pos, instance.tell
                    ensure
                      refute instance.closed?
                      instance.close
                      assert instance.closed?
                    end
                  end

                  decompressed_text.force_encoding text.encoding
                  assert_equal text, decompressed_text
                end
              end
            end
          end
        end

        def test_encoding
          TEXTS.each do |text|
            external_encoding = text.encoding

            get_compressor_options do |compressor_options|
              PORTION_LENGTHS.each do |portion_length|
                write_archive text, compressor_options

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  decompressed_text = "".b

                  ::File.open ARCHIVE_PATH, "rb" do |file|
                    instance = target.new file, decompressor_options

                    begin
                      result = instance.read 0
                      assert_equal result.encoding, Encoding::BINARY

                      loop do
                        result = instance.read portion_length
                        break if result.nil?

                        assert_equal result.encoding, Encoding::BINARY
                        decompressed_text << result
                      end
                    ensure
                      instance.close
                    end
                  end

                  decompressed_text.force_encoding external_encoding
                  assert_equal text, decompressed_text
                end
              end

              # We don't need to transcode between same encodings.
              (ENCODINGS - [external_encoding]).each do |internal_encoding|
                target_text = text.encode internal_encoding, TRANSCODE_OPTIONS

                write_archive text, compressor_options

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  decompressed_text = nil

                  ::File.open ARCHIVE_PATH, "rb" do |file|
                    instance = target.new(
                      file,
                      decompressor_options,
                      :external_encoding => external_encoding,
                      :internal_encoding => internal_encoding,
                      :transcode_options => TRANSCODE_OPTIONS
                    )
                    assert_equal instance.external_encoding, external_encoding
                    assert_equal instance.internal_encoding, internal_encoding
                    assert_equal instance.transcode_options, TRANSCODE_OPTIONS

                    begin
                      instance.set_encoding external_encoding, internal_encoding, TRANSCODE_OPTIONS
                      assert_equal instance.external_encoding, external_encoding
                      assert_equal instance.internal_encoding, internal_encoding
                      assert_equal instance.transcode_options, TRANSCODE_OPTIONS

                      decompressed_text = instance.read
                      assert_equal decompressed_text.encoding, internal_encoding
                    ensure
                      instance.close
                    end
                  end

                  assert_equal target_text, decompressed_text
                  assert target_text.valid_encoding?
                end
              end
            end
          end
        end

        def test_rewind
          TEXTS.each do |text|
            get_compressor_options do |compressor_options|
              write_archive text, compressor_options

              get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                decompressed_text = nil

                ::File.open ARCHIVE_PATH, "rb" do |file|
                  instance = target.new file, decompressor_options

                  begin
                    result_1 = instance.read

                    assert_equal instance.rewind, 0
                    assert_equal instance.pos, 0
                    assert_equal instance.pos, instance.tell

                    result_2 = instance.read
                    assert_equal result_1, result_2

                    decompressed_text = result_1
                  ensure
                    instance.close
                  end
                end

                decompressed_text.force_encoding text.encoding
                assert_equal text, decompressed_text
              end
            end
          end
        end

        def test_readpartial
          ::TCPServer.open PORT do |server|
            TEXTS.each do |text|
              PORTION_LENGTHS.each do |portion_length|
                [true, false].each do |with_buffer|
                  get_compressor_options do |compressor_options|
                    get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                      server_block_test(server, text, compressor_options, decompressor_options) do |instance|
                        prev_result       = "".b
                        decompressed_text = "".b

                        loop do
                          if with_buffer
                            result = instance.readpartial portion_length, prev_result
                            assert_equal result, prev_result
                          else
                            result = instance.readpartial portion_length
                          end

                          decompressed_text << result
                        rescue ::EOFError
                          break
                        end

                        decompressed_text
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def server_block_test(server, text, compressor_options, decompressor_options, &_block)
          compressed_text = String.compress text, compressor_options

          server_thread = ::Thread.new do
            socket = server.accept

            begin
              socket.write compressed_text
            ensure
              socket.close
            end
          end

          decompressed_text =
            ::TCPSocket.open "localhost", PORT do |socket|
              instance = target.new socket, decompressor_options

              begin
                yield instance
              ensure
                instance.close
              end
            end

          server_thread.join

          decompressed_text.force_encoding text.encoding
          assert_equal text, decompressed_text
        end

        # -- asynchronous --

        def test_read_nonblock
          ::TCPServer.open PORT do |server|
            TEXTS.each do |text|
              PORTION_LENGTHS.each do |portion_length|
                get_compressor_options do |compressor_options|
                  get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                    server_nonblock_test(server, text, compressor_options, decompressor_options) do |instance|
                      decompressed_text = "".b

                      loop do
                        decompressed_text << instance.read_nonblock(portion_length)
                      rescue ::IO::WaitReadable
                        ::IO.select [socket]
                      rescue ::EOFError
                        break
                      end

                      decompressed_text
                    end
                  end
                end
              end
            end
          end
        end

        def server_nonblock_test(server, text, compressor_options, decompressor_options, &_block)
          compressed_text = String.compress text, compressor_options

          server_thread = ::Thread.new do
            socket = server.accept

            begin
              loop do
                begin
                  bytes_written = socket.write_nonblock compressed_text
                rescue ::IO::WaitWritable
                  ::IO.select nil, [socket]
                  retry
                end

                compressed_text = compressed_text.byteslice bytes_written, compressed_text.bytesize - bytes_written
                break if compressed_text.bytesize == 0
              end
            ensure
              socket.close
            end
          end

          decompressed_text =
            ::TCPSocket.open "localhost", PORT do |socket|
              instance = target.new socket, decompressor_options

              begin
                yield instance
              ensure
                instance.close
              end
            end

          server_thread.join

          decompressed_text.force_encoding text.encoding
          assert_equal text, decompressed_text
        end

        # -----

        protected def write_archive(text, compressor_options)
          compressed_text = String.compress text, compressor_options
          ::File.write ARCHIVE_PATH, compressed_text
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

      Minitest << Reader
    end
  end
end
