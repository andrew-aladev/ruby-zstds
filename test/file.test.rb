# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/file"
require "zstds/file"

require_relative "minitest"
require_relative "option"

module ZSTDS
  module Test
    class File < ADSP::Test::File
      Target = ZSTDS::File
      Option = ZSTDS::Test::Option
    end

    Minitest << File
  end
end
