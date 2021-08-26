# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds"

require_relative "minitest"

module ZSTDS
  module Test
    class Version < Minitest::Test
      def test_versions
        refute_nil ZSTDS::VERSION
        refute_nil ZSTDS::LIBRARY_VERSION
      end
    end

    Minitest << Version
  end
end
