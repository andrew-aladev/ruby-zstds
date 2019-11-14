# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "English"

require_relative "../validation"

module ZSTDS
  module Stream
    module ReaderHelpers
      def getbyte
        read 1
      end

      def each_byte(&block)
        each_string method(:getbyte), &block
      end

      def readbyte
        readstring method(:getbyte)
      end

      def ungetbyte(byte)
        Validation.validate_string byte

        @buffer.prepend byte

        nil
      end

      # -- char --

      def getc
        if @external_encoding.nil?
          byte = getbyte
          return nil if byte.nil?

          return transcode_to_internal byte
        end

        char = ::String.new :encoding => ::Encoding::BINARY

        # Read one byte until valid string will appear.
        loop do
          byte = getbyte
          return nil if byte.nil?

          char << byte

          char.force_encoding @external_encoding
          return transcode_to_internal char if char.valid_encoding?

          char.force_encoding ::Encoding::BINARY
        end
      end

      def readchar
        readstring method(:getc)
      end

      def each_char(&block)
        each_string method(:getc), &block
      end

      def ungetc(char)
        ungetstring char
      end

      # -- lines --

      def gets(separator = $OUTPUT_RECORD_SEPARATOR, limit = nil)
        # Limit can be a first argument.
        if separator.is_a? ::Numeric
          limit     = separator
          separator = $OUTPUT_RECORD_SEPARATOR
        end

        line_ending =
          if separator.nil?
            nil
          else
            Validation.validate_string separator
            ::String.new separator, :encoding => target_encoding
          end

        Validation.validate_positive_integer limit unless limit.nil?

        line = ::String.new :encoding => target_encoding

        loop do
          char = getc

          if char.nil?
            return nil if line.empty?

            break
          end

          line << char

          break if
            (!line_ending.nil? && line.end_with?(line_ending)) ||
            (!limit.nil? && line.length >= limit)
        end

        @lineno += 1

        line
      end

      def readline
        readstring method(:gets)
      end

      def readlines
        lines = []
        each_line { |line| lines << line }

        lines
      end

      def each_line(&block)
        each_string method(:gets), &block
      end

      alias each each_line

      def ungetline(line)
        ungetstring line

        @lineno -= 1

        nil
      end

      # -- common --

      protected def readstring(each_proc)
        string = each_proc.call
        raise ::EOFError if string.nil?

        string
      end

      protected def each_string(each_proc, &block)
        return enum_for __method__ unless block.is_a? ::Proc

        loop do
          string = each_proc.call
          break if string.nil?

          yield string
        end

        nil
      end

      protected def ungetstring(string)
        Validation.validate_string string

        string = ::String.new string, :encoding => @internal_encoding unless @internal_encoding.nil?
        string = transcode_to_external string unless @external_encoding.nil?

        string.force_encoding ::Encoding::BINARY
        @buffer.prepend string

        nil
      end

      # -- etc --

      module ClassMethods
        def open(file_path, *args, &block)
          Validation.validate_string file_path
          Validation.validate_proc block

          ::File.open file_path, "rb" do |io|
            reader = new io, *args

            begin
              yield reader
            ensure
              reader.close
            end
          end
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end
