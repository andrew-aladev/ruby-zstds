# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "ocg"
require "zstds/dictionary"
require "zstds/option"

require_relative "common"
require_relative "validation"

module ZSTDS
  module Test
    module Option
      Dictionary = ZSTDS::Dictionary

      DICTIONARY_SAMPLES = Common::DICTIONARY_SAMPLES

      INVALID_COMPRESSOR_LEVELS = (
        Validation::INVALID_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_COMPRESSION_LEVEL - 1,
          ZSTDS::Option::MAX_COMPRESSION_LEVEL + 1
        ]
      )
      .freeze

      INVALID_WINDOW_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_WINDOW_LOG - 1,
          ZSTDS::Option::MAX_WINDOW_LOG + 1
        ]
      )
      .freeze

      INVALID_HASH_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_HASH_LOG - 1,
          ZSTDS::Option::MAX_HASH_LOG + 1
        ]
      )
      .freeze

      INVALID_CHAIN_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_CHAIN_LOG - 1,
          ZSTDS::Option::MAX_CHAIN_LOG + 1
        ]
      )
      .freeze

      INVALID_SEARCH_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_SEARCH_LOG - 1,
          ZSTDS::Option::MAX_SEARCH_LOG + 1
        ]
      )
      .freeze

      INVALID_MIN_MATCHES = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_MIN_MATCH - 1,
          ZSTDS::Option::MAX_MIN_MATCH + 1
        ]
      )
      .freeze

      INVALID_TARGET_LENGTHS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_TARGET_LENGTH - 1,
          ZSTDS::Option::MAX_TARGET_LENGTH + 1
        ]
      )
      .freeze

      INVALID_LDM_HASH_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_LDM_HASH_LOG - 1,
          ZSTDS::Option::MAX_LDM_HASH_LOG + 1
        ]
      )
      .freeze

      INVALID_LDM_MIN_MATCHES = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_LDM_MIN_MATCH - 1,
          ZSTDS::Option::MAX_LDM_MIN_MATCH + 1
        ]
      )
      .freeze

      INVALID_LDM_BUCKET_SIZE_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG - 1,
          ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG + 1
        ]
      )
      .freeze

      INVALID_LDM_HASH_RATE_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_LDM_HASH_RATE_LOG - 1,
          ZSTDS::Option::MAX_LDM_HASH_RATE_LOG + 1
        ]
      )
      .freeze

      INVALID_NB_WORKERS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_NB_WORKERS - 1,
          ZSTDS::Option::MAX_NB_WORKERS + 1
        ]
      )
      .freeze

      INVALID_JOB_SIZES = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_JOB_SIZE - 1,
          ZSTDS::Option::MAX_JOB_SIZE + 1
        ]
      )
      .freeze

      INVALID_OVERLAP_LOGS = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_OVERLAP_LOG - 1,
          ZSTDS::Option::MAX_OVERLAP_LOG + 1
        ]
      )
      .freeze

      INVALID_STRATEGIES = (
        Validation::INVALID_SYMBOLS - [nil] + %i[invalid_strategy]
      )
      .freeze

      INVALID_WINDOW_LOG_MAXES = (
        Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil] +
        [
          ZSTDS::Option::MIN_WINDOW_LOG_MAX - 1,
          ZSTDS::Option::MAX_WINDOW_LOG_MAX + 1
        ]
      )
      .freeze

      private_class_method def self.get_common_invalid_options(buffer_length_names, &block)
        Validation::INVALID_HASHES.each(&block)

        buffer_length_names.each do |name|
          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
            yield({ name => invalid_integer })
          end
        end

        Validation::INVALID_BOOLS.each do |invalid_bool|
          yield({ :gvl => invalid_bool })
        end
      end

      def self.get_invalid_compressor_options(buffer_length_names, &block)
        get_common_invalid_options buffer_length_names, &block

        INVALID_COMPRESSOR_LEVELS.each do |invalid_compression_level|
          yield({ :compression_level => invalid_compression_level })
        end

        INVALID_WINDOW_LOGS.each do |invalid_window_log|
          yield({ :window_log => invalid_window_log })
        end

        INVALID_HASH_LOGS.each do |invalid_hash_log|
          yield({ :hash_log => invalid_hash_log })
        end

        INVALID_CHAIN_LOGS.each do |invalid_chain_log|
          yield({ :chain_log => invalid_chain_log })
        end

        INVALID_SEARCH_LOGS.each do |invalid_search_log|
          yield({ :search_log => invalid_search_log })
        end

        INVALID_MIN_MATCHES.each do |invalid_min_match|
          yield({ :min_match => invalid_min_match })
        end

        INVALID_TARGET_LENGTHS.each do |invalid_target_length|
          yield({ :target_length => invalid_target_length })
        end

        INVALID_LDM_HASH_LOGS.each do |invalid_ldm_hash_log|
          yield({ :ldm_hash_log => invalid_ldm_hash_log })
        end

        INVALID_LDM_MIN_MATCHES.each do |invalid_ldm_min_match|
          yield({ :ldm_min_match => invalid_ldm_min_match })
        end

        INVALID_LDM_BUCKET_SIZE_LOGS.each do |invalid_ldm_bucket_size_log|
          yield({ :ldm_bucket_size_log => invalid_ldm_bucket_size_log })
        end

        INVALID_LDM_HASH_RATE_LOGS.each do |invalid_ldm_hash_rate_log|
          yield({ :ldm_hash_rate_log => invalid_ldm_hash_rate_log })
        end

        INVALID_NB_WORKERS.each do |invalid_nb_workers|
          yield({ :nb_workers => invalid_nb_workers })
        end

        INVALID_JOB_SIZES.each do |invalid_job_size|
          yield({ :job_size => invalid_job_size })
        end

        INVALID_OVERLAP_LOGS.each do |invalid_overlap_log|
          yield({ :overlap_log => invalid_overlap_log })
        end

        INVALID_STRATEGIES.each do |invalid_strategy|
          yield({ :strategy => invalid_strategy })
        end

        (Validation::INVALID_BOOLS - [nil]).each do |invalid_bool|
          yield({ :enable_long_distance_matching => invalid_bool })
          yield({ :content_size_flag             => invalid_bool })
          yield({ :checksum_flag                 => invalid_bool })
          yield({ :dict_id_flag                  => invalid_bool })
        end

        (Validation::INVALID_DICTIONARIES - [nil]).each do |invalid_dictionary|
          yield({ :dictionary => invalid_dictionary })
        end
      end

      def self.get_invalid_decompressor_options(buffer_length_names, &block)
        get_common_invalid_options buffer_length_names, &block

        INVALID_WINDOW_LOG_MAXES.each do |invalid_window_log_max|
          yield({ :window_log_max => invalid_window_log_max })
        end

        (Validation::INVALID_DICTIONARIES - [nil]).each do |invalid_dictionary|
          yield({ :dictionary => invalid_dictionary })
        end
      end

      # -----

      # "0" means default buffer length.
      BUFFER_LENGTHS = [
        0,
        1
      ]
      .freeze

      BOOLS = [
        true,
        false
      ]
      .freeze

      private_class_method def self.get_option_values(values, min, max)
        values.map { |value| [[value, min].max, max].min }
      end

      # Absolute min and max values works too slow.
      # Absolute max values are dangerous, it can provide out of memory exception.
      # We can use more reasonable min and max values defined in "zstd/lib/compress/zstd_compress.c".

      COMPRESSION_LEVELS = get_option_values(
        [3, 16],
        ZSTDS::Option::MIN_COMPRESSION_LEVEL,
        ZSTDS::Option::MAX_COMPRESSION_LEVEL
      )
      .freeze

      WINDOW_LOGS = get_option_values(
        [17, 22],
        ZSTDS::Option::MIN_WINDOW_LOG,
        ZSTDS::Option::MAX_WINDOW_LOG
      )
      .freeze

      HASH_LOGS = get_option_values(
        [17, 22],
        ZSTDS::Option::MIN_HASH_LOG,
        ZSTDS::Option::MAX_HASH_LOG
      )
      .freeze

      CHAIN_LOGS = get_option_values(
        [16, 23],
        ZSTDS::Option::MIN_CHAIN_LOG,
        ZSTDS::Option::MAX_CHAIN_LOG
      )
      .freeze

      SEARCH_LOGS = get_option_values(
        [1, 7],
        ZSTDS::Option::MIN_SEARCH_LOG,
        ZSTDS::Option::MAX_SEARCH_LOG
      )
      .freeze

      MIN_MATCHES = get_option_values(
        [3, 5],
        ZSTDS::Option::MIN_MIN_MATCH,
        ZSTDS::Option::MAX_MIN_MATCH
      )
      .freeze

      TARGET_LENGTHS = get_option_values(
        [0, 64],
        ZSTDS::Option::MIN_TARGET_LENGTH,
        ZSTDS::Option::MAX_TARGET_LENGTH
      )
      .freeze

      STRATEGIES = [
        ZSTDS::Option::STRATEGIES[ZSTDS::Option::STRATEGIES.length / 2]
      ]
      .freeze

      # LDM options are useless for small inputs.
      # Using default values.

      LDM_HASH_LOGS = get_option_values(
        [0],
        ZSTDS::Option::MIN_LDM_HASH_LOG,
        ZSTDS::Option::MAX_LDM_HASH_LOG
      )
      .freeze

      LDM_MIN_MATCHES = get_option_values(
        [0],
        ZSTDS::Option::MIN_LDM_MIN_MATCH,
        ZSTDS::Option::MAX_LDM_MIN_MATCH
      )
      .freeze

      LDM_BUCKET_SIZE_LOGS = get_option_values(
        [0],
        ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG,
        ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG
      )
      .freeze

      LDM_HASH_RATE_LOGS = get_option_values(
        [0],
        ZSTDS::Option::MIN_LDM_HASH_RATE_LOG,
        ZSTDS::Option::MAX_LDM_HASH_RATE_LOG
      )
      .freeze

      NB_WORKERS = get_option_values(
        [0, 2],
        ZSTDS::Option::MIN_NB_WORKERS,
        ZSTDS::Option::MAX_NB_WORKERS
      )
      .freeze

      JOB_SIZES = get_option_values(
        [64 * 1024, 512 * 1024],
        ZSTDS::Option::MIN_JOB_SIZE,
        ZSTDS::Option::MAX_JOB_SIZE
      )
      .freeze

      OVERLAP_LOGS = get_option_values(
        [0, 1],
        ZSTDS::Option::MIN_OVERLAP_LOG,
        ZSTDS::Option::MAX_OVERLAP_LOG
      )
      .freeze

      DICTIONARIES = [
        nil,
        Dictionary.train(DICTIONARY_SAMPLES)
      ]
      .freeze

      private_class_method def self.get_buffer_length_option_generator(buffer_length_names)
        OCG.new(
          buffer_length_names.map { |name| [name, BUFFER_LENGTHS] }.to_h
        )
      end

      def self.get_compressor_options_generator(buffer_length_names)
        buffer_length_generator = get_buffer_length_option_generator buffer_length_names

        # main

        general_generator = OCG.new(
          :compression_level => COMPRESSION_LEVELS
        )
        .or(
          :window_log    => WINDOW_LOGS,
          :hash_log      => HASH_LOGS,
          :chain_log     => CHAIN_LOGS,
          :search_log    => SEARCH_LOGS,
          :min_match     => MIN_MATCHES,
          :target_length => TARGET_LENGTHS,
          :strategy      => STRATEGIES
        )

        ldm_generator = OCG.new(
          :enable_long_distance_matching => [false]
        )
        .or(
          :enable_long_distance_matching => [true],
          :ldm_hash_log                  => LDM_HASH_LOGS,
          :ldm_min_match                 => LDM_MIN_MATCHES,
          :ldm_bucket_size_log           => LDM_BUCKET_SIZE_LOGS,
          :ldm_hash_rate_log             => LDM_HASH_RATE_LOGS
        )

        dictionary_generator = OCG.new(
          :dictionary => DICTIONARIES
        )

        main_generator = general_generator.mix(ldm_generator).mix dictionary_generator

        # thread

        thread_generator = OCG.new(
          :nb_workers => [NB_WORKERS.first]
        )

        if NB_WORKERS.first != NB_WORKERS.last
          # Multithreaded support is enabled.
          thread_generator = thread_generator.or(
            :nb_workers  => NB_WORKERS[1..-1],
            :job_size    => JOB_SIZES,
            :overlap_log => OVERLAP_LOGS
          )
        end

        thread_generator = thread_generator.mix(
          :gvl => BOOLS
        )

        # other

        other_generator = OCG.new(
          :content_size_flag => BOOLS
        )
        .mix(
          :checksum_flag => BOOLS
        )
        .mix(
          :dict_id_flag => BOOLS
        )

        # complete

        buffer_length_generator.mix(main_generator).mix(thread_generator).mix other_generator
      end

      def self.get_compatible_decompressor_options(compressor_options, buffer_length_name_mapping, &_block)
        decompressor_options = {
          :window_log_max => compressor_options[:window_log],
          :dictionary     => compressor_options[:dictionary]
        }

        buffer_length_name_mapping.each do |compressor_name, decompressor_name|
          decompressor_options[decompressor_name] = compressor_options[compressor_name]
        end

        yield decompressor_options
      end
    end
  end
end
