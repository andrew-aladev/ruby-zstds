# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "dictionary"
require_relative "error"
require_relative "validation"

module ZSTDS
  module Option
    DEFAULT_BUFFER_LENGTH = 0

    COMPRESSOR_DEFAULTS = {
      :compression_level             => nil,
      :window_log                    => nil,
      :hash_log                      => nil,
      :chain_log                     => nil,
      :search_log                    => nil,
      :min_match                     => nil,
      :target_length                 => nil,
      :strategy                      => nil,
      :enable_long_distance_matching => nil,
      :ldm_hash_log                  => nil,
      :ldm_min_match                 => nil,
      :ldm_bucket_size_log           => nil,
      :ldm_hash_rate_log             => nil,
      :content_size_flag             => nil,
      :checksum_flag                 => nil,
      :dict_id_flag                  => nil,
      :nb_workers                    => nil,
      :job_size                      => nil,
      :overlap_log                   => nil,
      :dictionary                    => nil
    }
    .freeze

    DECOMPRESSOR_DEFAULTS = {
      :window_log_max => nil
    }
    .freeze

    def self.get_compressor_options(options, buffer_length_names)
      Validation.validate_hash options

      buffer_length_defaults = buffer_length_names.each_with_object({}) { |name, defaults| defaults[name] = DEFAULT_BUFFER_LENGTH }
      options                = COMPRESSOR_DEFAULTS.merge(buffer_length_defaults).merge options

      buffer_length_names.each { |name| Validation.validate_not_negative_integer options[name] }

      compression_level = options[:compression_level]
      unless compression_level.nil?
        Validation.validate_integer compression_level
        raise ValidateError, "invalid compression level" if
          compression_level < MIN_COMPRESSION_LEVEL || compression_level > MAX_COMPRESSION_LEVEL
      end

      window_log = options[:window_log]
      unless window_log.nil?
        Validation.validate_not_negative_integer window_log
        raise ValidateError, "invalid window log" if
          window_log < MIN_WINDOW_LOG || window_log > MAX_WINDOW_LOG
      end

      hash_log = options[:hash_log]
      unless hash_log.nil?
        Validation.validate_not_negative_integer hash_log
        raise ValidateError, "invalid hash log" if
          hash_log < MIN_HASH_LOG || hash_log > MAX_HASH_LOG
      end

      chain_log = options[:chain_log]
      unless chain_log.nil?
        Validation.validate_not_negative_integer chain_log
        raise ValidateError, "invalid chain log" if
          chain_log < MIN_CHAIN_LOG || chain_log > MAX_CHAIN_LOG
      end

      search_log = options[:search_log]
      unless search_log.nil?
        Validation.validate_not_negative_integer search_log
        raise ValidateError, "invalid search log" if
          search_log < MIN_SEARCH_LOG || search_log > MAX_SEARCH_LOG
      end

      min_match = options[:min_match]
      unless min_match.nil?
        Validation.validate_not_negative_integer min_match
        raise ValidateError, "invalid min match" if
          min_match < MIN_MIN_MATCH || min_match > MAX_MIN_MATCH
      end

      target_length = options[:target_length]
      unless target_length.nil?
        Validation.validate_not_negative_integer target_length
        raise ValidateError, "invalid target length" if
          target_length < MIN_TARGET_LENGTH || target_length > MAX_TARGET_LENGTH
      end

      strategy = options[:strategy]
      unless strategy.nil?
        Validation.validate_symbol strategy
        raise ValidateError, "invalid strategy" unless STRATEGIES.include? strategy
      end

      enable_long_distance_matching = options[:enable_long_distance_matching]
      Validation.validate_bool enable_long_distance_matching unless enable_long_distance_matching.nil?

      ldm_hash_log = options[:ldm_hash_log]
      unless ldm_hash_log.nil?
        Validation.validate_not_negative_integer ldm_hash_log
        raise ValidateError, "invalid ldm hash log" if
          ldm_hash_log < MIN_LDM_HASH_LOG || ldm_hash_log > MAX_LDM_HASH_LOG
      end

      ldm_min_match = options[:ldm_min_match]
      unless ldm_min_match.nil?
        Validation.validate_not_negative_integer ldm_min_match
        raise ValidateError, "invalid ldm min match" if
          ldm_min_match < MIN_LDM_MIN_MATCH || ldm_min_match > MAX_LDM_MIN_MATCH
      end

      ldm_bucket_size_log = options[:ldm_bucket_size_log]
      unless ldm_bucket_size_log.nil?
        Validation.validate_not_negative_integer ldm_bucket_size_log
        raise ValidateError, "invalid ldm bucket size log" if
          ldm_bucket_size_log < MIN_LDM_BUCKET_SIZE_LOG || ldm_bucket_size_log > MAX_LDM_BUCKET_SIZE_LOG
      end

      ldm_hash_rate_log = options[:ldm_hash_rate_log]
      unless ldm_hash_rate_log.nil?
        Validation.validate_not_negative_integer ldm_hash_rate_log
        raise ValidateError, "invalid ldm hash rate log" if
          ldm_hash_rate_log < MIN_LDM_HASH_RATE_LOG || ldm_hash_rate_log > MAX_LDM_HASH_RATE_LOG
      end

      content_size_flag = options[:content_size_flag]
      Validation.validate_bool content_size_flag unless content_size_flag.nil?

      checksum_flag = options[:checksum_flag]
      Validation.validate_bool checksum_flag unless checksum_flag.nil?

      dict_id_flag = options[:dict_id_flag]
      Validation.validate_bool dict_id_flag unless dict_id_flag.nil?

      nb_workers = options[:nb_workers]
      unless nb_workers.nil?
        Validation.validate_not_negative_integer nb_workers
        raise ValidateError, "invalid nb workers" if
          nb_workers < MIN_NB_WORKERS || nb_workers > MAX_NB_WORKERS
      end

      job_size = options[:job_size]
      unless job_size.nil?
        Validation.validate_not_negative_integer job_size
        raise ValidateError, "invalid job size" if
          job_size < MIN_JOB_SIZE || job_size > MAX_JOB_SIZE
      end

      overlap_log = options[:overlap_log]
      unless overlap_log.nil?
        Validation.validate_not_negative_integer overlap_log
        raise ValidateError, "invalid overlap log" if
          overlap_log < MIN_OVERLAP_LOG || overlap_log > MAX_OVERLAP_LOG
      end

      dictionary = options[:dictionary]
      unless dictionary.nil?
        raise ValidateError, "invalid dictionary" unless dictionary.is_a? Dictionary
      end

      options
    end

    def self.get_decompressor_options(options, buffer_length_names)
      Validation.validate_hash options

      buffer_length_defaults = buffer_length_names.each_with_object({}) { |name, defaults| defaults[name] = DEFAULT_BUFFER_LENGTH }
      options                = DECOMPRESSOR_DEFAULTS.merge(buffer_length_defaults).merge options

      buffer_length_names.each { |name| Validation.validate_not_negative_integer options[name] }

      window_log_max = options[:window_log_max]
      unless window_log_max.nil?
        Validation.validate_not_negative_integer window_log_max
        raise ValidateError, "invalid window log max" if
          window_log_max < MIN_WINDOW_LOG_MAX || window_log_max > MAX_WINDOW_LOG_MAX
      end

      options
    end
  end
end
