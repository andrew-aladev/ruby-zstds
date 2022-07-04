# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "error"
require_relative "validation"

module ZSTDS
  # ZSTDS::Dictionary class.
  class Dictionary
    # Current train defaults.
    TRAIN_DEFAULTS = {
      :gvl      => false,
      :capacity => 0
    }
    .freeze

    # Current finalize defaults.
    FINALIZE_DEFAULTS = {
      :gvl                => false,
      :max_size           => 0,
      :dictionary_options => {}
    }
    .freeze

    # Current finalize dictionary defaults.
    FINALIZE_DICTIONARY_DEFAULTS = {
      :compression_level  => 0,
      :notification_level => 0,
      :dictionary_id      => 0
    }
    .freeze

    # Reads current +buffer+ binary data.
    attr_reader :buffer

    # Initializes compressor.
    # Uses +buffer+ binary data.
    def initialize(buffer)
      Validation.validate_string buffer
      raise ValidateError, "dictionary buffer should not be empty" if buffer.empty?

      @buffer = buffer
    end

    # Trains dictionary.
    # Uses +samples+ list of binary datas.
    # Uses +options+ options hash.
    # Option +gvl+ is global interpreter lock enabled.
    # Option +capacity+ capacity of dictionary buffer.
    # Returns dictionary based on new buffer.
    def self.train(samples, options = {})
      validate_samples samples

      Validation.validate_hash options

      options = TRAIN_DEFAULTS.merge options

      Validation.validate_bool                 options[:gvl]
      Validation.validate_not_negative_integer options[:capacity]

      buffer = train_buffer samples, options
      new buffer
    end

    # Finalizes dictionary.
    # Uses +content+ binary data.
    # Uses +samples+ list of binary datas.
    # Uses +options+ options hash.
    # Option +gvl+ is global interpreter lock enabled.
    # Option +max_size+ max size of dictionary buffer.
    # Option +dictionary_options+ standard dictionary options hash.
    # Returns dictionary based on new buffer.
    def self.finalize(content, samples, options = {})
      Validation.validate_string content
      raise ValidateError, "content should not be empty" if content.empty?

      validate_samples samples

      Validation.validate_hash options

      options = FINALIZE_DEFAULTS.merge options

      Validation.validate_bool                 options[:gvl]
      Validation.validate_not_negative_integer options[:max_size]
      Validation.validate_hash                 options[:dictionary_options]

      dictionary_options = FINALIZE_DICTIONARY_DEFAULTS.merge options[:dictionary_options]

      compression_level = dictionary_options[:compression_level]
      Validation.validate_integer compression_level
      raise ValidateError, "invalid compression level" if
        compression_level < Option::MIN_COMPRESSION_LEVEL || compression_level > Option::MAX_COMPRESSION_LEVEL

      Validation.validate_not_negative_integer dictionary_options[:notification_level]
      Validation.validate_not_negative_integer dictionary_options[:dictionary_id]

      buffer = finalize_buffer content, samples, options
      new buffer
    end

    # Raises error when +samples+ are not list of not empty strings.
    def self.validate_samples(samples)
      Validation.validate_array samples

      samples.each do |sample|
        Validation.validate_string sample
        raise ValidateError, "dictionary sample should not be empty" if sample.empty?
      end
    end

    # Returns current dictionary id.
    def id
      self.class.get_buffer_id @buffer
    end

    # Returns current dictionary header size.
    def header_size
      self.class.get_header_size @buffer
    end
  end
end
