# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "error"
require_relative "validation"

module ZSTDS
  class Dictionary
    TRAIN_DEFAULTS = {
      :capacity => 0
    }
    .freeze

    attr_reader :buffer

    def initialize(buffer)
      Validation.validate_string buffer
      raise ValidateError, "dictionary buffer should not be empty" if buffer.empty?

      @buffer = buffer
    end

    def id
      self.class.get_buffer_id @buffer
    end

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
