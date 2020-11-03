# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "stringio"

module ZSTDS
  module Test
    module Validation
      NOOP_PROC = proc {} # no-op

      TYPES = [
        nil,
        1,
        1.1,
        "1",
        true,
        "a",
        :a,
        {},
        [],
        $stdout,
        ::StringIO,
        NOOP_PROC
      ]
      .freeze

      INVALID_INTEGERS = (TYPES - [1]).freeze
      INVALID_NUMBERS  = (TYPES - [1, 1.1]).freeze
      INVALID_BOOLS    = (TYPES - [true]).freeze
      INVALID_STRINGS  = (TYPES - %w[1 a]).freeze
      INVALID_SYMBOLS  = (TYPES - %i[a]).freeze
      INVALID_ARRAYS   = (TYPES - [[]]).freeze
      INVALID_HASHES   = (TYPES - [{}]).freeze
      INVALID_IOS      = (TYPES - [$stdout, ::StringIO]).freeze
      INVALID_CHARS    = (INVALID_NUMBERS & INVALID_STRINGS).freeze

      INVALID_POSITIVE_INTEGERS     = (INVALID_INTEGERS + [0, -1]).freeze
      INVALID_NOT_NEGATIVE_INTEGERS = (INVALID_POSITIVE_INTEGERS - [0]).freeze
      INVALID_DICTIONARIES          = TYPES

      INVALID_ENCODINGS = %w[
        ISO_8859_0
        UTF-15
        UTF-33
      ]
      .freeze
    end
  end
end
