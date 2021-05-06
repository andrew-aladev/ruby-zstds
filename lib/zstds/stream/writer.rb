# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require_relative "abstract"
require_relative "raw/compressor"
require_relative "writer_helpers"

module ZSTDS
  module Stream
    class Writer < Abstract
      include WriterHelpers

      def initialize(destination_io, options = {}, *args)
        @options = options

        super destination_io, options, *args
      end

      protected def create_raw_stream
        Raw::Compressor.new @options
      end

      # -- synchronous --

      def write(*objects)
        write_remaining_buffer

        bytes_written = 0

        objects.each do |object|
          source         = transcode object.to_s
          bytes_written += raw_wrapper :write, source
        end

        @pos += bytes_written

        bytes_written
      end

      def flush
        finish :flush

        @io.flush

        self
      end

      def rewind
        finish :close

        super
      end

      def close
        finish :close

        super
      end

      protected def finish(method_name)
        write_remaining_buffer

        raw_wrapper method_name
      end

      protected def write_remaining_buffer
        return nil if @buffer.bytesize.zero?

        @io.write @buffer

        reset_buffer
      end

      protected def raw_wrapper(method_name, *args)
        @raw_stream.send(method_name, *args) { |portion| @io.write portion }
      end

      # -- asynchronous --

      # IO write nonblock can raise wait writable error.
      # After resolving this error user may provide same content again.
      # It is not possible to revert accepted content after error.
      # So we have to accept content after processing IO write nonblock.
      # It means that first write nonblock won't call IO write nonblock.
      def write_nonblock(object, *options)
        return 0 unless write_remaining_buffer_nonblock(*options)

        source         = transcode object.to_s
        bytes_written  = raw_nonblock_wrapper :write, source
        @pos          += bytes_written

        bytes_written
      end

      def flush_nonblock(*options)
        return false unless finish_nonblock :flush, *options

        @io.flush

        true
      end

      def rewind_nonblock(*options)
        return false unless finish_nonblock :close, *options

        method(:rewind).super_method.call

        true
      end

      def close_nonblock(*options)
        return false unless finish_nonblock :close, *options

        method(:close).super_method.call

        true
      end

      protected def finish_nonblock(method_name, *options)
        return false unless write_remaining_buffer_nonblock(*options)

        raw_nonblock_wrapper method_name

        write_remaining_buffer_nonblock(*options)
      end

      protected def write_remaining_buffer_nonblock(*options)
        return true if @buffer.bytesize.zero?

        bytes_written = @io.write_nonblock @buffer, *options
        return false if bytes_written.zero?

        @buffer = @buffer.byteslice bytes_written, @buffer.bytesize - bytes_written

        @buffer.bytesize.zero?
      end

      protected def raw_nonblock_wrapper(method_name, *args)
        @raw_stream.send(method_name, *args) { |portion| @buffer << portion }
      end

      # -- common --

      protected def transcode(data)
        data = data.encode @external_encoding, **@transcode_options unless @external_encoding.nil?
        data
      end
    end
  end
end
