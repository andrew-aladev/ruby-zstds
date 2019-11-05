# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "error"
require_relative "validation"

module ZSTDS
  class Dictionary < NativeDictionary
    DEFAULTS = {
      :capacity => 0
    }
    .freeze

    def initialize(samples, options = {})
      Validation.validate_array samples

      samples.each do |sample|
        Validation.validate_string sample
        raise ValidateError, "dictionary sample should not be empty" if sample.empty?
      end

      Validation.validate_hash options

      options = DEFAULTS.merge options

      Validation.validate_not_negative_integer options[:capacity]

      super samples, options
    end
  end
end
