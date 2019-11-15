# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "socket"

require "zstds/stream/writer"
require "zstds/string"

require_relative "abstract"
require_relative "../common"
require_relative "../minitest"
require_relative "../option"

module ZSTDS
  module Test
    module Stream
      class Writer < Abstract
        Target = ZSTDS::Stream::Writer
        String = ZSTDS::String

        ARCHIVE_PATH      = Common::ARCHIVE_PATH
        PORT              = Common::PORT
        ENCODINGS         = Common::ENCODINGS
        TRANSCODE_OPTIONS = Common::TRANSCODE_OPTIONS
        TEXTS             = Common::TEXTS
        PORTION_LENGTHS   = Common::PORTION_LENGTHS

        BUFFER_LENGTH_NAMES   = %i[destination_buffer_length].freeze
        BUFFER_LENGTH_MAPPING = { :destination_buffer_length => :destination_buffer_length }.freeze

        def test_invalid_initialize
          get_invalid_compressor_options do |invalid_options|
            assert_raises ValidateError do
              target.new ::STDOUT, invalid_options
            end
          end

          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
            assert_raises ValidateError do
              target.new ::STDOUT, :pledged_size => invalid_integer
            end
          end

          super
        end

        # -- synchronous --

        def test_write
          TEXTS.each do |text|
            PORTION_LENGTHS.each do |portion_length|
              sources = get_sources text, portion_length

              get_compressor_options do |compressor_options|
                ::File.open ARCHIVE_PATH, "wb" do |file|
                  instance = target.new file, compressor_options.merge(:pledged_size => text.bytesize)

                  begin
                    sources.each_slice(2) do |current_sources|
                      instance.write(*current_sources)
                      instance.flush
                    end

                    assert_equal instance.pos, text.bytesize
                    assert_equal instance.pos, instance.tell
                  ensure
                    refute instance.closed?
                    instance.close
                    assert instance.closed?
                  end
                end

                compressed_text = ::File.read ARCHIVE_PATH

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  check_text text, compressed_text, decompressor_options
                end
              end
            end
          end
        end

        def test_encoding
          TEXTS.each do |text|
            # We don't need to transcode between same encodings.
            (ENCODINGS - [text.encoding]).each do |external_encoding|
              target_text = text.encode external_encoding, TRANSCODE_OPTIONS

              get_compressor_options do |compressor_options|
                ::File.open ARCHIVE_PATH, "wb" do |file|
                  instance = target.new(
                    file,
                    compressor_options.merge(:pledged_size => target_text.bytesize),
                    :external_encoding => external_encoding,
                    :transcode_options => TRANSCODE_OPTIONS
                  )
                  assert_equal instance.external_encoding, external_encoding
                  assert_equal instance.transcode_options, TRANSCODE_OPTIONS

                  begin
                    instance.set_encoding external_encoding, nil, TRANSCODE_OPTIONS
                    assert_equal instance.external_encoding, external_encoding
                    assert_equal instance.transcode_options, TRANSCODE_OPTIONS

                    instance.write text
                  ensure
                    instance.close
                  end
                end

                compressed_text = ::File.read ARCHIVE_PATH

                get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                  check_text target_text, compressed_text, decompressor_options
                  assert target_text.valid_encoding?
                end
              end
            end
          end
        end

        def test_rewind
          get_compressor_options do |compressor_options|
            compressed_texts = []

            ::File.open ARCHIVE_PATH, "wb" do |file|
              instance = target.new file, compressor_options

              begin
                TEXTS.each do |text|
                  instance.write text
                  instance.flush

                  assert_equal instance.pos, text.bytesize
                  assert_equal instance.pos, instance.tell

                  assert_equal instance.rewind, 0

                  compressed_texts << ::File.read(ARCHIVE_PATH)

                  assert_equal instance.pos, 0
                  assert_equal instance.pos, instance.tell

                  file.truncate 0
                end
              ensure
                instance.close
              end
            end

            TEXTS.each.with_index do |text, index|
              compressed_text = compressed_texts[index]

              get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                check_text text, compressed_text, decompressor_options
              end
            end
          end
        end

        # -- asynchronous --

        def test_write_nonblock
          ::TCPServer.open PORT do |server|
            TEXTS.each do |text|
              PORTION_LENGTHS.each do |portion_length|
                sources = get_sources text, portion_length

                get_compressor_options do |compressor_options|
                  get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                    server_nonblock_test(server, text, portion_length, compressor_options, decompressor_options) do |instance|
                      sources.each do |source|
                        loop do
                          begin
                            bytes_written = instance.write_nonblock source
                          rescue ::IO::WaitWritable
                            ::IO.select nil, [socket]
                            retry
                          end

                          source = source.byteslice bytes_written, source.bytesize - bytes_written
                          break if source.bytesize == 0
                        end
                      end

                      loop do
                        begin
                          is_flushed = instance.flush_nonblock
                        rescue ::IO::WaitWritable
                          ::IO.select nil, [socket]
                          retry
                        end

                        break if is_flushed
                      end

                      assert_equal instance.pos, text.bytesize
                      assert_equal instance.pos, instance.tell

                    ensure
                      refute instance.closed?

                      loop do
                        begin
                          is_closed = instance.close_nonblock
                        rescue ::IO::WaitWritable
                          ::IO.select nil, [socket]
                          retry
                        end

                        break if is_closed
                      end

                      assert instance.closed?
                    end
                  end
                end
              end
            end
          end
        end

        def server_nonblock_test(server, text, portion_length, compressor_options, decompressor_options, &_block)
          compressed_text = "".b

          server_thread = ::Thread.new do
            socket = server.accept

            begin
              loop do
                compressed_text << socket.read_nonblock(portion_length)
              rescue ::IO::WaitReadable
                ::IO.select [socket]
              rescue ::EOFError
                break
              end
            ensure
              socket.close
            end
          end

          TCPSocket.open "localhost", PORT do |socket|
            instance = target.new socket, compressor_options

            begin
              yield instance
            ensure
              instance.close
            end
          end

          server_thread.join

          check_text text, compressed_text, decompressor_options
        end

        def test_rewind_nonblock
          get_compressor_options do |compressor_options|
            compressed_texts = []

            ::File.open ARCHIVE_PATH, "wb" do |file|
              instance = target.new file, compressor_options

              begin
                TEXTS.each do |text|
                  instance.write text
                  instance.flush

                  assert_equal instance.pos, text.bytesize
                  assert_equal instance.pos, instance.tell

                  loop do
                    begin
                      is_rewinded = instance.rewind_nonblock
                    rescue ::IO::WaitWritable
                      ::IO.select nil, [socket]
                      retry
                    end

                    break if is_rewinded
                  end

                  compressed_texts << ::File.read(ARCHIVE_PATH)

                  assert_equal instance.pos, 0
                  assert_equal instance.pos, instance.tell

                  file.truncate 0
                end
              ensure
                instance.close
              end
            end

            TEXTS.each.with_index do |text, index|
              compressed_text = compressed_texts[index]

              get_compatible_decompressor_options(compressor_options) do |decompressor_options|
                check_text text, compressed_text, decompressor_options
              end
            end
          end
        end

        # -----

        protected def get_sources(text, portion_length)
          sources = text
            .chars
            .each_slice(portion_length)
            .map(&:join)

          return ["".b] if sources.empty?

          sources
        end

        protected def check_text(text, compressed_text, decompressor_options)
          decompressed_text = String.decompress compressed_text, decompressor_options
          decompressed_text.force_encoding text.encoding

          assert_equal text, decompressed_text
        end

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

      Minitest << Writer
    end
  end
end
