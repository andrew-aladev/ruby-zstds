# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "securerandom"

module ZSTDS
  module Test
    module Common
      BASE_PATH = ::File.expand_path ::File.join(::File.dirname(__FILE__), "..").freeze
      TEMP_PATH = ::File.join(BASE_PATH, "tmp").freeze

      SOURCE_PATH  = ::File.join(TEMP_PATH, "source").freeze
      ARCHIVE_PATH = ::File.join(TEMP_PATH, "archive").freeze

      [
        SOURCE_PATH,
        ARCHIVE_PATH
      ]
      .each { |path| FileUtils.touch path }

      PORT = 54_030

      ENCODINGS = %w[
        binary
        UTF-8
        UTF-16LE
      ]
      .map { |encoding_name| ::Encoding.find encoding_name }
      .freeze

      TRANSCODE_OPTIONS = {
        :invalid => :replace,
        :undef   => :replace,
        :replace => "?"
      }
      .freeze

      def self.generate_texts(*sources)
        sources.flat_map do |source|
          ENCODINGS.map do |encoding|
            source.encode encoding, TRANSCODE_OPTIONS
          end
        end
      end

      TEXTS = generate_texts(
        "",
        ::SecureRandom.random_bytes(1 << 8) # 256 B
      )
      .freeze

      LARGE_TEXTS = generate_texts(
        ::SecureRandom.random_bytes(1 << 21) # 2 MB
      )
      .freeze

      PORTION_LENGTHS = [
        1,
        128
      ]
      .freeze

      DICTIONARY_SAMPLES = Common.generate_texts(
        ::SecureRandom.random_bytes(1 << 10), # 1 KB
        ::SecureRandom.random_bytes(1 << 12), # 4 KB
        ::SecureRandom.random_bytes(1 << 14), # 16 KB
        ::SecureRandom.random_bytes(1 << 16)  # 64 KB
      )
      .shuffle
      .freeze
    end
  end
end
