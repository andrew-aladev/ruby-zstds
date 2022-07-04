# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/test/validation"

module ZSTDS
  module Test
    module Validation
      include ADSP::Test::Validation

      INVALID_DICTIONARIES = TYPES
    end
  end
end
