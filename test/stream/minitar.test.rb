# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "minitar"
require "zstds/stream/reader"
require "zstds/stream/writer"

require_relative "../common"
require_relative "../minitest"

module ZSTDS
  module Test
    module Stream
      class MinitarTest < Minitest::Test
        Reader = ZSTDS::Stream::Reader
        Writer = ZSTDS::Stream::Writer

        ARCHIVE_PATH = Common::ARCHIVE_PATH
        LARGE_TEXTS  = Common::LARGE_TEXTS

        def test_tar
          LARGE_TEXTS.each do |text|
            Writer.open ARCHIVE_PATH do |writer|
              Minitar::Writer.open writer do |tar|
                tar.add_file_simple "file", :data => text
              end
            end

            Reader.open ARCHIVE_PATH do |reader|
              Minitar::Reader.open reader do |tar|
                tar.each_entry do |entry|
                  assert_equal entry.name, "file"

                  decompressed_text = entry.read
                  decompressed_text.force_encoding text.encoding

                  assert_equal text, decompressed_text
                end
              end
            end
          end
        end
      end

      Minitest << MinitarTest
    end
  end
end
