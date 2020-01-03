# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require_relative "delegates"
require_relative "stat"
require_relative "../error"
require_relative "../validation"

module ZSTDS
  module Stream
    class Abstract
      # Native stream is not seekable by design.
      # Related methods like "seek" and "pos=" can't be implemented.

      # It is not possible to maintain correspondance between bytes consumed from source and bytes written to destination by design.
      # We will consume all source bytes and maintain buffer with remaining destination data.

      include Delegates

      attr_reader :io
      attr_reader :stat
      attr_reader :external_encoding
      attr_reader :internal_encoding
      attr_reader :transcode_options
      attr_reader :pos
      alias tell pos

      def initialize(io, options = {})
        @raw_stream = create_raw_stream

        Validation.validate_io io
        @io = io

        @stat = Stat.new @io.stat

        set_encoding options[:external_encoding], options[:internal_encoding], options[:transcode_options]
        reset_buffer
        reset_io_advise

        @pos = 0
      end

      # -- buffer --

      protected def reset_buffer
        @buffer = ::String.new :encoding => ::Encoding::BINARY
      end

      # -- advise --

      protected def reset_io_advise
        # Both compressor and decompressor need sequential io access.
        @io.advise :sequential
      rescue ::Errno::ESPIPE # rubocop:disable Lint/SuppressedException
        # ok
      end

      def advise
        # Noop
        nil
      end

      # -- encoding --

      def set_encoding(*args)
        external_encoding, internal_encoding, transcode_options = process_set_encoding_arguments(*args)

        set_target_encoding :@external_encoding, external_encoding
        set_target_encoding :@internal_encoding, internal_encoding
        @transcode_options = transcode_options

        self
      end

      protected def process_set_encoding_arguments(*args)
        external_encoding = args[0]

        unless external_encoding.nil? || external_encoding.is_a?(::Encoding)
          Validation.validate_string external_encoding

          # First argument can be "external_encoding:internal_encoding".
          match = %r{(.+?):(.+)}.match external_encoding

          unless match.nil?
            external_encoding = match[0]
            internal_encoding = match[1]

            transcode_options = args[1]
            Validation.validate_hash transcode_options unless transcode_options.nil?

            return [external_encoding, internal_encoding, transcode_options]
          end
        end

        internal_encoding = args[1]
        Validation.validate_string internal_encoding \
          unless internal_encoding.nil? || internal_encoding.is_a?(::Encoding)

        transcode_options = args[2]
        Validation.validate_hash transcode_options unless transcode_options.nil?

        [external_encoding, internal_encoding, transcode_options]
      end

      protected def set_target_encoding(name, value)
        unless value.nil? || value.is_a?(::Encoding)
          begin
            value = ::Encoding.find value
          rescue ::ArgumentError
            raise ValidateError, "invalid #{name} encoding"
          end
        end

        instance_variable_set name, value
      end

      protected def target_encoding
        return @internal_encoding unless @internal_encoding.nil?
        return @external_encoding unless @external_encoding.nil?

        ::Encoding::BINARY
      end

      # -- etc --

      def rewind
        @raw_stream = create_raw_stream

        @io.rewind
        reset_buffer
        reset_io_advise

        @pos = 0

        0
      end

      def close
        @io.close

        nil
      end

      def closed?
        @raw_stream.closed? && @io.closed?
      end

      def to_io
        self
      end
    end
  end
end
