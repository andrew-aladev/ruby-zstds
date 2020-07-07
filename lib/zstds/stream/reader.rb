# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require_relative "abstract"
require_relative "raw/decompressor"
require_relative "reader_helpers"
require_relative "../validation"

module ZSTDS
  module Stream
    class Reader < Abstract
      include ReaderHelpers

      attr_accessor :lineno

      def initialize(source_io, options = {}, *args)
        @options = options

        super source_io, *args

        initialize_source_buffer_length
        reset_io_remainder

        @lineno = 0
      end

      protected def initialize_source_buffer_length
        source_buffer_length = @options[:source_buffer_length]
        Validation.validate_not_negative_integer source_buffer_length unless source_buffer_length.nil?

        source_buffer_length = Buffer::DEFAULT_SOURCE_BUFFER_LENGTH_FOR_DECOMPRESSOR \
          if source_buffer_length.nil? || source_buffer_length.zero?

        @source_buffer_length = source_buffer_length
      end

      protected def create_raw_stream
        Raw::Decompressor.new @options
      end

      protected def reset_io_remainder
        @io_remainder = ::String.new :encoding => ::Encoding::BINARY
      end

      # -- synchronous --

      def read(bytes_to_read = nil, out_buffer = nil)
        Validation.validate_not_negative_integer bytes_to_read unless bytes_to_read.nil?
        Validation.validate_string out_buffer unless out_buffer.nil?

        return ::String.new :encoding => ::Encoding::BINARY if !bytes_to_read.nil? && bytes_to_read.zero?

        unless bytes_to_read.nil?
          return nil if eof?

          read_more_to_buffer until @buffer.bytesize >= bytes_to_read || @io.eof?

          return read_bytes_from_buffer bytes_to_read, out_buffer
        end

        read_more_to_buffer until @io.eof?

        result = @buffer
        reset_buffer
        @pos += result.bytesize

        result.force_encoding @external_encoding unless @external_encoding.nil?
        result = transcode_to_internal result
        result = out_buffer.replace result unless out_buffer.nil?

        result
      end

      protected def read_more_to_buffer
        io_data = @io.read @source_buffer_length
        append_io_data_to_buffer io_data
      end

      def readpartial(bytes_to_read = nil, out_buffer = nil)
        raise ::EOFError if eof?

        readpartial_to_buffer until @buffer.bytesize >= bytes_to_read || @io.eof?

        read_bytes_from_buffer bytes_to_read, out_buffer
      end

      protected def readpartial_to_buffer
        io_data = @io.readpartial @source_buffer_length
        append_io_data_to_buffer io_data
      end

      def rewind
        raw_wrapper :close

        reset_io_remainder

        super
      end

      def close
        raw_wrapper :close

        super
      end

      # -- asynchronous --

      def read_nonblock(bytes_to_read, out_buffer = nil, *options)
        raise ::EOFError if eof?

        read_more_to_buffer_nonblock(*options) until @buffer.bytesize >= bytes_to_read || @io.eof?

        read_bytes_from_buffer bytes_to_read, out_buffer
      end

      protected def read_more_to_buffer_nonblock(*options)
        io_data = @io.read_nonblock @source_buffer_length, *options
        append_io_data_to_buffer io_data
      end

      # -- common --

      def eof?
        @io.eof? && @buffer.bytesize.zero?
      end

      protected def read_bytes_from_buffer(bytes_to_read, out_buffer)
        bytes_read = [@buffer.bytesize, bytes_to_read].min

        # Result uses buffer binary encoding.
        result   = @buffer.byteslice 0, bytes_read
        @buffer  = @buffer.byteslice bytes_read, @buffer.bytesize - bytes_read
        @pos    += bytes_read

        result = out_buffer.replace result unless out_buffer.nil?
        result
      end

      protected def append_io_data_to_buffer(io_data)
        io_portion    = @io_remainder + io_data
        bytes_read    = raw_wrapper :read, io_portion
        @io_remainder = io_portion.byteslice bytes_read, io_portion.bytesize - bytes_read

        # We should just ignore case when "io.eof?" appears but "io_remainder" is not empty.
        # Ancient compress implementations can write bytes from not initialized buffer parts to output.
        raw_wrapper :flush if @io.eof?
      end

      protected def transcode_to_internal(data)
        data = data.encode @internal_encoding, **@transcode_options unless @internal_encoding.nil?
        data
      end

      # We should be able to return data back to buffer.
      # We won't use any transcode options because transcoded data should be backward compatible.
      protected def transcode_to_external(data)
        data = data.encode @external_encoding unless @external_encoding.nil?
        data
      end

      protected def raw_wrapper(method_name, *args)
        @raw_stream.send(method_name, *args) { |portion| @buffer << portion }
      end
    end
  end
end
