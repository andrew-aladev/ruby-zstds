# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "socket"
require "zstds/stream/reader"
require "zstds/string"
require "stringio"

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

        ARCHIVE_PATH          = Common::ARCHIVE_PATH
        ENCODINGS             = Common::ENCODINGS
        TRANSCODE_OPTIONS     = Common::TRANSCODE_OPTIONS
        TEXTS                 = Common::TEXTS
        LARGE_TEXTS           = Common::LARGE_TEXTS
        PORTION_LENGTHS       = Common::PORTION_LENGTHS
        LARGE_PORTION_LENGTHS = Common::LARGE_PORTION_LENGTHS

        BUFFER_LENGTH_NAMES   = %i[source_buffer_length destination_buffer_length].freeze
        BUFFER_LENGTH_MAPPING = {
          :source_buffer_length      => :destination_buffer_length,
          :destination_buffer_length => :source_buffer_length
        }
        .freeze

        def test_invalid_initialize
          get_invalid_decompressor_options do |invalid_options|
            assert_raises ValidateError do
              target.new ::StringIO.new, invalid_options
            end
          end

          super
        end

        # -- synchronous --

        def test_invalid_read
          instance = target.new ::StringIO.new

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
          instance                  = target.new ::StringIO.new(corrupted_compressed_text)

          assert_raises DecompressorCorruptedSourceError do
            instance.read
          end
        end

        def test_read
          parallel_compressor_options do |compressor_options|
            TEXTS.each do |text|
              archive     = get_archive text, compressor_options
              prev_result = "".b

              Option::BOOLS.each do |with_buffer|
                PORTION_LENGTHS.each do |portion_length|
                  get_compatible_decompressor_options compressor_options do |decompressor_options|
                    instance          = target.new ::StringIO.new(archive), decompressor_options
                    decompressed_text = "".b

                    begin
                      result = instance.read 0
                      assert_equal "", result

                      loop do
                        prev_eof = instance.eof?

                        result =
                          if with_buffer
                            instance.read portion_length, prev_result
                          else
                            instance.read portion_length
                          end

                        if result.nil?
                          assert instance.eof?
                          break
                        end

                        refute prev_eof unless archive.bytesize.zero?

                        assert_equal prev_result, result if with_buffer
                        decompressed_text << result
                      end

                      assert_equal instance.pos, decompressed_text.bytesize
                      assert_equal instance.pos, instance.tell
                    ensure
                      refute instance.closed?
                      instance.close
                      assert instance.closed?
                    end

                    decompressed_text.force_encoding text.encoding
                    assert_equal text, decompressed_text
                  end
                end

                get_compatible_decompressor_options compressor_options do |decompressor_options|
                  instance          = target.new ::StringIO.new(archive), decompressor_options
                  decompressed_text = nil

                  begin
                    prev_eof = instance.eof?

                    if with_buffer
                      decompressed_text = instance.read nil, prev_result
                      assert_equal prev_result, decompressed_text
                    else
                      decompressed_text = instance.read
                    end

                    assert instance.eof?
                    refute prev_eof unless archive.bytesize.zero?

                    assert_equal instance.pos, decompressed_text.bytesize
                    assert_equal instance.pos, instance.tell
                  ensure
                    refute instance.closed?
                    instance.close
                    assert instance.closed?
                  end

                  decompressed_text.force_encoding text.encoding
                  assert_equal text, decompressed_text
                end
              end
            end
          end
        end

        def test_read_with_large_texts
          options_generator = OCG.new(
            :text        => LARGE_TEXTS,
            :with_buffer => Option::BOOLS
          )

          Common.parallel_options options_generator do |options|
            text        = options[:text]
            with_buffer = options[:with_buffer]

            archive     = get_archive text
            prev_result = "".b

            LARGE_PORTION_LENGTHS.each do |portion_length|
              instance          = target.new ::StringIO.new(archive)
              decompressed_text = "".b

              begin
                loop do
                  result =
                    if with_buffer
                      instance.read portion_length, prev_result
                    else
                      instance.read portion_length
                    end

                  break if result.nil?

                  assert_equal prev_result, result if with_buffer
                  decompressed_text << result
                end
              ensure
                instance.close
              end

              decompressed_text.force_encoding text.encoding
              assert_equal text, decompressed_text
            end

            instance          = target.new ::StringIO.new(archive)
            decompressed_text = nil

            begin
              if with_buffer
                decompressed_text = instance.read nil, prev_result
                assert_equal prev_result, decompressed_text
              else
                decompressed_text = instance.read
              end
            ensure
              instance.close
            end

            decompressed_text.force_encoding text.encoding
            assert_equal text, decompressed_text
          end
        end

        def test_encoding
          parallel_compressor_options do |compressor_options|
            TEXTS.each do |text|
              external_encoding = text.encoding
              archive           = get_archive text, compressor_options

              PORTION_LENGTHS.each do |portion_length|
                get_compatible_decompressor_options compressor_options do |decompressor_options|
                  instance          = target.new ::StringIO.new(archive), decompressor_options
                  decompressed_text = "".b

                  begin
                    result = instance.read 0
                    assert_equal Encoding::BINARY, result.encoding

                    loop do
                      result = instance.read portion_length
                      break if result.nil?

                      assert_equal Encoding::BINARY, result.encoding
                      decompressed_text << result
                    end
                  ensure
                    instance.close
                  end

                  decompressed_text.force_encoding external_encoding
                  assert_equal text, decompressed_text
                end
              end

              # We don't need to transcode between same encodings.
              (ENCODINGS - [external_encoding]).each do |internal_encoding|
                target_text = text.encode internal_encoding, **TRANSCODE_OPTIONS

                get_compatible_decompressor_options compressor_options do |decompressor_options|
                  instance = target.new(
                    ::StringIO.new(archive),
                    decompressor_options,
                    :external_encoding => external_encoding,
                    :internal_encoding => internal_encoding,
                    :transcode_options => TRANSCODE_OPTIONS
                  )

                  assert_equal external_encoding, instance.external_encoding
                  assert_equal internal_encoding, instance.internal_encoding
                  assert_equal TRANSCODE_OPTIONS, instance.transcode_options

                  decompressed_text = nil

                  begin
                    instance.set_encoding external_encoding, internal_encoding, TRANSCODE_OPTIONS
                    assert_equal external_encoding, instance.external_encoding
                    assert_equal internal_encoding, instance.internal_encoding
                    assert_equal TRANSCODE_OPTIONS, instance.transcode_options

                    decompressed_text = instance.read
                    assert_equal internal_encoding, decompressed_text.encoding
                  ensure
                    instance.close
                  end

                  assert_equal target_text, decompressed_text
                  assert target_text.valid_encoding?
                end
              end
            end
          end
        end

        def test_rewind
          parallel_compressor_options do |compressor_options, worker_index|
            archive_path = Common.get_path ARCHIVE_PATH, worker_index

            TEXTS.each do |text|
              write_archive archive_path, text, compressor_options

              get_compatible_decompressor_options compressor_options do |decompressor_options|
                decompressed_text = nil

                ::File.open archive_path, "rb" do |file|
                  instance = target.new file, decompressor_options

                  begin
                    result_1 = instance.read

                    assert_equal 0, instance.rewind
                    assert_equal 0, instance.pos
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

        def test_eof
          compressed_text = String.compress "ab"
          instance        = target.new ::StringIO.new(compressed_text)

          refute instance.eof?

          byte = instance.read 1
          refute instance.eof?
          assert_equal "a", byte

          byte = instance.read 1
          assert instance.eof?
          assert_equal "b", byte
        end

        # -- asynchronous --

        def test_invalid_readpartial_and_read_nonblock
          instance = target.new ::StringIO.new

          Validation::INVALID_NOT_NEGATIVE_INTEGERS.each do |invalid_integer|
            assert_raises ValidateError do
              instance.readpartial invalid_integer
            end
            assert_raises ValidateError do
              instance.read_nonblock invalid_integer
            end
          end

          (Validation::INVALID_STRINGS - [nil]).each do |invalid_string|
            assert_raises ValidateError do
              instance.readpartial 0, invalid_string
            end
            assert_raises ValidateError do
              instance.read_nonblock 0, invalid_string
            end
          end

          corrupted_compressed_text = String.compress("1111").reverse

          instance = target.new ::StringIO.new(corrupted_compressed_text)

          assert_raises DecompressorCorruptedSourceError do
            instance.readpartial 1
          end

          instance = target.new ::StringIO.new(corrupted_compressed_text)

          assert_raises DecompressorCorruptedSourceError do
            instance.read_nonblock 1
          end
        end

        def test_readpartial
          IO.pipe do |read_io, write_io|
            instance = target.new read_io
            write_io.close

            assert_raises ::EOFError do
              instance.readpartial 1
            end
          end

          nonblock_server do |server|
            parallel_compressor_options do |compressor_options|
              TEXTS.each do |text|
                PORTION_LENGTHS.each do |portion_length|
                  Option::BOOLS.each do |with_buffer|
                    nonblock_test server, text, portion_length, compressor_options do |instance|
                      prev_result       = "".b
                      decompressed_text = "".b

                      loop do
                        if with_buffer
                          result = instance.readpartial portion_length, prev_result
                          assert_equal prev_result, result
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

        def test_read_nonblock
          IO.pipe do |read_io, write_io|
            instance = target.new read_io

            assert_raises ::IO::WaitReadable do
              instance.read_nonblock 1
            end

            write_io.close

            assert_raises ::EOFError do
              instance.read_nonblock 1
            end
          end

          nonblock_server do |server|
            parallel_compressor_options do |compressor_options|
              TEXTS.each do |text|
                PORTION_LENGTHS.each do |portion_length|
                  nonblock_test server, text, portion_length, compressor_options do |instance, socket|
                    decompressed_text = "".b

                    loop do
                      begin
                        decompressed_text << instance.read_nonblock(portion_length)
                      rescue ::IO::WaitReadable
                        ::IO.select [socket]
                        retry
                      rescue ::EOFError
                        break
                      end

                      begin
                        decompressed_text << instance.readpartial(portion_length)
                      rescue ::EOFError
                        break
                      end

                      result = instance.read portion_length
                      break if result.nil?

                      decompressed_text << result
                    end

                    decompressed_text
                  end
                end
              end
            end
          end
        end

        def test_read_nonblock_with_large_texts
          nonblock_server do |server|
            Common.parallel LARGE_TEXTS do |text|
              LARGE_PORTION_LENGTHS.each do |portion_length|
                nonblock_test server, text, portion_length do |instance, socket|
                  decompressed_text = "".b

                  loop do
                    begin
                      decompressed_text << instance.read_nonblock(portion_length)
                    rescue ::IO::WaitReadable
                      ::IO.select [socket]
                      retry
                    rescue ::EOFError
                      break
                    end

                    begin
                      decompressed_text << instance.readpartial(portion_length)
                    rescue ::EOFError
                      break
                    end

                    result = instance.read portion_length
                    break if result.nil?

                    decompressed_text << result
                  end

                  decompressed_text
                end
              end
            end
          end
        end

        # -- nonblock test --

        protected def nonblock_server
          # Server need just to redirect content for client.

          ::TCPServer.open 0 do |server|
            # Server loop will be processed in separate (parent) thread.
            # Child threads will be collected for later usage.
            child_lock    = ::Mutex.new
            child_threads = ::Set.new

            parent_thread = ::Thread.new do
              loop do
                child_thread = ::Thread.start server.accept do |socket|
                  result = "".b

                  # Reading head.
                  result_size, portion_length = socket.read(16).unpack "QQ"
                  next if result_size.zero?

                  # Reading result.
                  loop do
                    begin
                      result << socket.read_nonblock(portion_length)
                    rescue ::IO::WaitReadable
                      ::IO.select [socket]
                      retry
                    end

                    break if result.bytesize == result_size
                  end

                  # Writing result.
                  loop do
                    begin
                      bytes_written = socket.write_nonblock result
                    rescue ::IO::WaitWritable
                      ::IO.select nil, [socket]
                      retry
                    end

                    result       = result.byteslice bytes_written, result.bytesize - bytes_written
                    result_size -= bytes_written

                    break if result_size.zero?
                  end

                ensure
                  socket.close

                  # Removing current child thread.
                  child_lock.synchronize { child_threads.delete ::Thread.current }
                end

                # Adding new child thread.
                child_lock.synchronize { child_threads.add child_thread }
              end
            end

            # Processing client.
            begin
              yield server
            ensure
              # We need to kill parent thread when client has finished.
              # So server won't be able to create new child threads.
              # Than we can join all remaining child threads.
              parent_thread.kill.join
              child_threads.each(&:join)
            end
          end
        end

        protected def nonblock_test(server, text, portion_length, compressor_options = {}, &_block)
          port            = server.addr[1]
          compressed_text = String.compress text, compressor_options

          processor = proc do |decompressor_options|
            decompressed_text = ::TCPSocket.open "localhost", port do |socket|
              # Writing head.
              head = [compressed_text.bytesize, portion_length].pack "QQ"
              socket.write head

              # Writing compressed text.
              socket.write compressed_text

              instance = target.new socket, decompressor_options

              begin
                yield instance, socket
              ensure
                instance.close
              end
            end

            # Testing decompressed text.
            decompressed_text.force_encoding text.encoding
            assert_equal text, decompressed_text
          end

          if compressor_options.empty?
            processor.call({})
          else
            get_compatible_decompressor_options compressor_options do |decompressor_options|
              processor.call decompressor_options
            end
          end
        end

        # -----

        protected def get_archive(text, compressor_options = {})
          String.compress text, compressor_options
        end

        protected def write_archive(archive_path, text, compressor_options = {})
          compressed_text = String.compress text, compressor_options
          ::File.write archive_path, compressed_text, :mode => "wb"
        end

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

      Minitest << Reader
    end
  end
end
