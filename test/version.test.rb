# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/version"
require "zstds"

require_relative "minitest"

module ZSTDS
  module Test
    class Version < ADSP::Test::Version
      def test_version
        refute_nil ZSTDS::VERSION
        refute_nil ZSTDS::LIBRARY_VERSION
      end
    end

    Minitest << Version
  end
end
