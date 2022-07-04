# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "dictionary"
require_relative "error"
require_relative "validation"

module ZSTDS
  # ZSTDS::Option module.
  module Option
    # Current default buffer length.
    DEFAULT_BUFFER_LENGTH = 0

    # Current compressor defaults.
    COMPRESSOR_DEFAULTS = {
      # Enables global VM lock where possible.
      :gvl                           => false,
      # Compression level.
      :compression_level             => nil,
      # Maximum back-reference distance (power of 2).
      :window_log                    => nil,
      # Size of the initial probe table (power of 2).
      :hash_log                      => nil,
      # Size of the multi-probe search table (power of 2).
      :chain_log                     => nil,
      # Number of search attempts (power of 2).
      :search_log                    => nil,
      # Minimum size of searched matches.
      :min_match                     => nil,
      # Distance between match sampling (for :fast strategy),
      #   length of match considered "good enough" for (for other strategies).
      :target_length                 => nil,
      # Choses strategy.
      :strategy                      => nil,
      # Enables long distance matching.
      :enable_long_distance_matching => nil,
      # Size of the table for long distance matching (power of 2).
      :ldm_hash_log                  => nil,
      # Minimum match size for long distance matcher.
      :ldm_min_match                 => nil,
      # Log size of each bucket in the LDM hash table for collision resolution.
      :ldm_bucket_size_log           => nil,
      # Frequency of inserting/looking up entries into the LDM hash table.
      :ldm_hash_rate_log             => nil,
      # Enables writing of content size into frame header (if known).
      :content_size_flag             => nil,
      # Enables writing of 32-bits checksum of content at end of frame.
      :checksum_flag                 => nil,
      # Enables writing of dictionary id into frame header.
      :dict_id_flag                  => nil,
      # Number of threads spawned in parallel.
      :nb_workers                    => nil,
      # Size of job (nb_workers >= 1).
      :job_size                      => nil,
      # Overlap size, as a fraction of window size.
      :overlap_log                   => nil,
      # Chose dictionary.
      :dictionary                    => nil
    }
    .freeze

    # Current decompressor defaults.
    DECOMPRESSOR_DEFAULTS = {
      # Enables global VM lock where possible.
      :gvl            => false,
      # Size limit (power of 2).
      :window_log_max => nil,
      # Chose dictionary.
      :dictionary     => nil
    }
    .freeze

    # Processes compressor +options+ and +buffer_length_names+.
    # Option: +:source_buffer_length+ source buffer length.
    # Option: +:destination_buffer_length+ destination buffer length.
    # Option: +:gvl+ enables global VM lock where possible.
    # Option: +:compression_level+ compression level.
    # Option: +:window_log+ maximum back-reference distance (power of 2).
    # Option: +:hash_log+ size of the initial probe table (power of 2).
    # Option: +:chain_log+ size of the multi-probe search table (power of 2).
    # Option: +:search_log+ number of search attempts (power of 2).
    # Option: +:min_match+ minimum size of searched matches.
    # Option: +:target_length+ distance between match sampling (for :fast strategy),
    #   length of match considered "good enough" for (for other strategies).
    # Option: +:strategy+ choses strategy.
    # Option: +:ldm_hash_log+ size of the table for long distance matching (power of 2).
    # Option: +:ldm_min_match+ minimum match size for long distance matcher.
    # Option: +:ldm_bucket_size_log+ log size of each bucket in the LDM hash table for collision resolution.
    # Option: +:ldm_hash_rate_log+ frequency of inserting/looking up entries into the LDM hash table.
    # Option: +:content_size_flag+ enables writing of content size into frame header (if known).
    # Option: +:checksum_flag+ enables writing of 32-bits checksum of content at end of frame.
    # Option: +:dict_id_flag+ enables writing of dictionary id into frame header.
    # Option: +:nb_workers+ number of threads spawned in parallel.
    # Option: +:job_size+ size of job (nb_workers >= 1).
    # Option: +:overlap_log+ overlap size, as a fraction of window size.
    # Option: +:dictionary+ chose dictionary.
    # Returns processed compressor options.
    def self.get_compressor_options(options, buffer_length_names)
      Validation.validate_hash options

      buffer_length_defaults = buffer_length_names.each_with_object({}) do |name, defaults|
        defaults[name] = DEFAULT_BUFFER_LENGTH
      end

      options = COMPRESSOR_DEFAULTS.merge(buffer_length_defaults).merge options

      buffer_length_names.each { |name| Validation.validate_not_negative_integer options[name] }

      Validation.validate_bool options[:gvl]

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
      raise ValidateError, "invalid dictionary" unless
        dictionary.nil? || dictionary.is_a?(Dictionary)

      options
    end

    # Processes decompressor +options+ and +buffer_length_names+.
    # Option: +:source_buffer_length+ source buffer length.
    # Option: +:destination_buffer_length+ destination buffer length.
    # Option: +:gvl+ enables global VM lock where possible.
    # Option: +:window_log_max+ size limit (power of 2).
    # Returns processed decompressor options.
    def self.get_decompressor_options(options, buffer_length_names)
      Validation.validate_hash options

      buffer_length_defaults = buffer_length_names.each_with_object({}) do |name, defaults|
        defaults[name] = DEFAULT_BUFFER_LENGTH
      end

      options = DECOMPRESSOR_DEFAULTS.merge(buffer_length_defaults).merge options

      buffer_length_names.each { |name| Validation.validate_not_negative_integer options[name] }

      Validation.validate_bool options[:gvl]

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
