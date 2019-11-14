# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "English"

require_relative "../error"
require_relative "../validation"

module ZSTDS
  module Stream
    module WriterHelpers
      def <<(object)
        write object
      end

      def print(*objects)
        objects.each do |object|
          write object
          write $OUTPUT_FIELD_SEPARATOR unless $OUTPUT_FIELD_SEPARATOR.nil?
        end

        write $OUTPUT_RECORD_SEPARATOR unless $OUTPUT_RECORD_SEPARATOR.nil?

        nil
      end

      def printf(*args)
        write sprintf(*args)

        nil
      end

      def putc(object, encoding: ::Encoding::BINARY)
        if object.is_a? ::Numeric
          write object.chr(encoding)
        elsif object.is_a? ::String
          write object[0]
        else
          raise ValidateError, "invalid object: \"#{object}\" for putc"
        end

        object
      end

      def puts(*objects)
        objects.each do |object|
          if object.is_a? ::Array
            puts(*object)
            next
          end

          source  = object.to_s
          newline = "\n".encode source.encoding

          # Do not add newline if source ends with newline.
          if source.end_with? newline
            write source
          else
            write source + newline
          end
        end

        nil
      end

      # -- etc --

      module ClassMethods
        def open(file_path, *args, &block)
          Validation.validate_string file_path
          Validation.validate_proc block

          ::File.open file_path, "wb" do |io|
            writer = new io, *args

            begin
              yield writer
            ensure
              writer.close
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
