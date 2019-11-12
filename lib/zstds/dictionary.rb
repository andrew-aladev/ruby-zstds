# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "error"
require_relative "validation"

module ZSTDS
  class Dictionary < NativeDictionary
    TRAIN_DEFAULTS = {
      :capacity => 0
    }
    .freeze

    def self.train(samples, options = {})
      Validation.validate_array samples

      samples.each do |sample|
        Validation.validate_string sample
        raise ValidateError, "dictionary sample should not be empty" if sample.empty?
      end

      Validation.validate_hash options

      options = TRAIN_DEFAULTS.merge options

      Validation.validate_not_negative_integer options[:capacity]

      buffer = train_buffer samples, options
      new buffer
    end
  end
end
