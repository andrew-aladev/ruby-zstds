# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/option"
require "ocg"

require_relative "validation"

module ZSTDS
  module Test
    module Option
      private_class_method def self.get_invalid_buffer_length_options(buffer_length_names, &_block)
        buffer_length_names.each do |name|
          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
            yield({ name => invalid_integer })
          end
        end
      end

      def self.get_invalid_compressor_options(buffer_length_names, &block)
        Validation::INVALID_HASHES.each do |invalid_hash|
          yield invalid_hash
        end

        get_invalid_buffer_length_options buffer_length_names, &block

        (Validation::INVALID_INTEGERS - [nil]).each do |invalid_integer|
          yield({ :compression_level => invalid_integer })
        end

        yield({ :compression_level => ZSTDS::Option::MIN_COMPRESSION_LEVEL - 1 })
        yield({ :compression_level => ZSTDS::Option::MAX_COMPRESSION_LEVEL + 1 })

        (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
          yield({ :window_log          => invalid_integer })
          yield({ :hash_log            => invalid_integer })
          yield({ :chain_log           => invalid_integer })
          yield({ :search_log          => invalid_integer })
          yield({ :min_match           => invalid_integer })
          yield({ :target_length       => invalid_integer })
          yield({ :ldm_hash_log        => invalid_integer })
          yield({ :ldm_min_match       => invalid_integer })
          yield({ :ldm_bucket_size_log => invalid_integer })
          yield({ :ldm_hash_rate_log   => invalid_integer })
          yield({ :nb_workers          => invalid_integer })
          yield({ :job_size            => invalid_integer })
          yield({ :overlap_log         => invalid_integer })
        end

        yield({ :window_log => ZSTDS::Option::MIN_WINDOW_LOG - 1 })
        yield({ :window_log => ZSTDS::Option::MAX_WINDOW_LOG + 1 })

        yield({ :hash_log => ZSTDS::Option::MIN_HASH_LOG - 1 })
        yield({ :hash_log => ZSTDS::Option::MAX_HASH_LOG + 1 })

        yield({ :chain_log => ZSTDS::Option::MIN_CHAIN_LOG - 1 })
        yield({ :chain_log => ZSTDS::Option::MAX_CHAIN_LOG + 1 })

        yield({ :search_log => ZSTDS::Option::MIN_SEARCH_LOG - 1 })
        yield({ :search_log => ZSTDS::Option::MAX_SEARCH_LOG + 1 })

        yield({ :min_match => ZSTDS::Option::MIN_MIN_MATCH - 1 })
        yield({ :min_match => ZSTDS::Option::MAX_MIN_MATCH + 1 })

        yield({ :target_length => ZSTDS::Option::MIN_TARGET_LENGTH - 1 })
        yield({ :target_length => ZSTDS::Option::MAX_TARGET_LENGTH + 1 })

        yield({ :ldm_hash_log => ZSTDS::Option::MIN_LDM_HASH_LOG - 1 })
        yield({ :ldm_hash_log => ZSTDS::Option::MAX_LDM_HASH_LOG + 1 })

        yield({ :ldm_min_match => ZSTDS::Option::MIN_LDM_MIN_MATCH - 1 })
        yield({ :ldm_min_match => ZSTDS::Option::MAX_LDM_MIN_MATCH + 1 })

        yield({ :ldm_bucket_size_log => ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG - 1 })
        yield({ :ldm_bucket_size_log => ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG + 1 })

        yield({ :ldm_hash_rate_log => ZSTDS::Option::MIN_LDM_HASH_RATE_LOG - 1 })
        yield({ :ldm_hash_rate_log => ZSTDS::Option::MAX_LDM_HASH_RATE_LOG + 1 })

        yield({ :nb_workers => ZSTDS::Option::MIN_NB_WORKERS - 1 })
        yield({ :nb_workers => ZSTDS::Option::MAX_NB_WORKERS + 1 })

        yield({ :job_size => ZSTDS::Option::MIN_JOB_SIZE - 1 })
        yield({ :job_size => ZSTDS::Option::MAX_JOB_SIZE + 1 })

        yield({ :overlap_log => ZSTDS::Option::MIN_OVERLAP_LOG - 1 })
        yield({ :overlap_log => ZSTDS::Option::MAX_OVERLAP_LOG + 1 })

        (Validation::INVALID_SYMBOLS - [nil]).each do |invalid_symbol|
          yield({ :strategy => invalid_symbol })
        end

        yield({ :strategy => :invalid_strategy })

        (Validation::INVALID_BOOLS - [nil]).each do |invalid_bool|
          yield({ :enable_long_distance_matching => invalid_bool })
          yield({ :content_size_flag             => invalid_bool })
          yield({ :checksum_flag                 => invalid_bool })
          yield({ :dict_id_flag                  => invalid_bool })
        end
      end

      def self.get_invalid_decompressor_options(buffer_length_names, &block)
        Validation::INVALID_HASHES.each do |invalid_hash|
          yield invalid_hash
        end

        get_invalid_buffer_length_options buffer_length_names, &block

        (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).each do |invalid_integer|
          yield({ :window_log_max => invalid_integer })
        end

        yield({ :window_log_max => ZSTDS::Option::MIN_WINDOW_LOG_MAX - 1 })
        yield({ :window_log_max => ZSTDS::Option::MAX_WINDOW_LOG_MAX + 1 })
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

      # Max values are dangerous, it can provide out of memory exception.
      # Using recommended values.

      COMPRESSION_LEVELS = [
        ZSTDS::Option::MIN_COMPRESSION_LEVEL,
        [3, ZSTDS::Option::MAX_COMPRESSION_LEVEL].min
      ]
      .freeze

      WINDOW_LOGS = [
        ZSTDS::Option::MIN_WINDOW_LOG,
        [23, ZSTDS::Option::MAX_WINDOW_LOG].min
      ]
      .freeze

      HASH_LOGS = [
        ZSTDS::Option::MIN_HASH_LOG,
        [22, ZSTDS::Option::MAX_HASH_LOG].min
      ]
      .freeze

      CHAIN_LOGS = [
        ZSTDS::Option::MIN_CHAIN_LOG,
        [23, ZSTDS::Option::MAX_CHAIN_LOG].min
      ]
      .freeze

      SEARCH_LOGS = [
        ZSTDS::Option::MIN_SEARCH_LOG,
        [5, ZSTDS::Option::MAX_SEARCH_LOG].min
      ]
      .freeze

      MIN_MATCHES = [
        ZSTDS::Option::MIN_MIN_MATCH,
        [4, ZSTDS::Option::MAX_MIN_MATCH].min
      ]
      .freeze

      TARGET_LENGTHS = [
        ZSTDS::Option::MIN_TARGET_LENGTH,
        [64, ZSTDS::Option::MAX_TARGET_LENGTH].min
      ]
      .freeze

      STRATEGIES = [
        ZSTDS::Option::STRATEGIES.first,
        ZSTDS::Option::STRATEGIES[[4, ZSTDS::Option::STRATEGIES.length - 1].min]
      ]
      .freeze

      LDM_HASH_LOGS = [
        ZSTDS::Option::MIN_LDM_HASH_LOG,
        [23 - 7, ZSTDS::Option::MAX_LDM_HASH_LOG].min
      ]
      .freeze

      LDM_MIN_MATCHES = [
        ZSTDS::Option::MIN_LDM_MIN_MATCH,
        [64, ZSTDS::Option::MAX_LDM_MIN_MATCH].min
      ]
      .freeze

      LDM_BUCKET_SIZE_LOGS = [
        ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG,
        [3, ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG].min
      ]
      .freeze

      LDM_HASH_RATE_LOGS = [
        ZSTDS::Option::MIN_LDM_HASH_RATE_LOG,
        [7, ZSTDS::Option::MAX_LDM_HASH_RATE_LOG].min
      ]
      .freeze

      NB_WORKERS = [
        ZSTDS::Option::MIN_NB_WORKERS,
        [2, ZSTDS::Option::MAX_NB_WORKERS].min
      ]
      .freeze

      JOB_SIZES = [
        ZSTDS::Option::MIN_JOB_SIZE,
        [256, ZSTDS::Option::MAX_JOB_SIZE].min
      ]
      .freeze

      OVERLAP_LOGS = [
        ZSTDS::Option::MIN_OVERLAP_LOG,
        [1, ZSTDS::Option::MAX_OVERLAP_LOG].min
      ]
      .freeze

      WINDOW_LOG_MAXES = [
        ZSTDS::Option::MIN_WINDOW_LOG_MAX,
        [12, ZSTDS::Option::MAX_WINDOW_LOG_MAX].min
      ]
      .freeze

      private_class_method def self.get_buffer_length_option_generator(buffer_length_names)
        OCG.new(
          Hash[buffer_length_names.map { |name| [name, BUFFER_LENGTHS] }]
        )
      end

      def self.get_compressor_options(buffer_length_names, &_block)
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

        main_generator = general_generator.and ldm_generator

        # other

        flags_generator = OCG.new(
          # TODO: content size is broken https://github.com/facebook/zstd/issues/1863.
          :content_size_flag => [true],
          :checksum_flag     => BOOLS,
          :dict_id_flag      => BOOLS
        )

        thread_generator = OCG.new(
          :nb_workers => [NB_WORKERS.first]
        )

        if NB_WORKERS.first != NB_WORKERS.last
          # Multithreaded support is enabled.
          thread_generator = thread_generator.or(
            :nb_workers  => [NB_WORKERS.last],
            :job_size    => JOB_SIZES,
            :overlap_log => OVERLAP_LOGS
          )
        end

        other_generator = flags_generator.mix thread_generator

        # complete

        complete_generator = buffer_length_generator.and(main_generator).mix other_generator

        yield complete_generator.next until complete_generator.finished?
      end

      private_class_method def self.get_decompressor_options(buffer_length_names, &_block)
        buffer_length_generator = get_buffer_length_option_generator buffer_length_names

        main_generator = OCG.new(
          :window_log_max => WINDOW_LOG_MAXES
        )

        complete_generator = buffer_length_generator.and main_generator

        yield complete_generator.next until complete_generator.finished?
      end

      def self.get_compatible_decompressor_options(compressor_options, buffer_length_name_mapping, &_block)
        buffer_length_names = buffer_length_name_mapping.values

        get_decompressor_options(buffer_length_names) do |decompressor_options|
          same_buffer_length_values = buffer_length_name_mapping.all? do |compressor_name, decompressor_name|
            decompressor_options[decompressor_name] == compressor_options[compressor_name]
          end

          yield decompressor_options if same_buffer_length_values
        end
      end
    end
  end
end
