# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/option"

require_relative "validation"

module ZSTDS
  module Test
    module Option
      private_class_method def self.get_invalid_buffer_length_options(buffer_length_names)
        buffer_length_names.flat_map do |name|
          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).map do |invalid_integer|
            { name => invalid_integer }
          end
        end
      end

      def self.get_invalid_compressor_options(buffer_length_names)
        [
          Validation::INVALID_HASHES,
          get_invalid_buffer_length_options(buffer_length_names),
          [
            { :compression_level => ZSTDS::Option::MIN_COMPRESSION_LEVEL - 1 },
            { :compression_level => ZSTDS::Option::MAX_COMPRESSION_LEVEL + 1 },
            { :window_log => ZSTDS::Option::MIN_WINDOW_LOG - 1 },
            { :window_log => ZSTDS::Option::MAX_WINDOW_LOG + 1 },
            { :hash_log => ZSTDS::Option::MIN_HASH_LOG - 1 },
            { :hash_log => ZSTDS::Option::MAX_HASH_LOG + 1 },
            { :chain_log => ZSTDS::Option::MIN_CHAIN_LOG - 1 },
            { :chain_log => ZSTDS::Option::MAX_CHAIN_LOG + 1 },
            { :search_log => ZSTDS::Option::MIN_SEARCH_LOG - 1 },
            { :search_log => ZSTDS::Option::MAX_SEARCH_LOG + 1 },
            { :min_match => ZSTDS::Option::MIN_MIN_MATCH - 1 },
            { :min_match => ZSTDS::Option::MAX_MIN_MATCH + 1 },
            { :target_length => ZSTDS::Option::MIN_TARGET_LENGTH - 1 },
            { :target_length => ZSTDS::Option::MAX_TARGET_LENGTH + 1 },
            { :strategy => :invalid_strategy },
            { :ldm_hash_log => ZSTDS::Option::MIN_LDM_HASH_LOG - 1 },
            { :ldm_hash_log => ZSTDS::Option::MAX_LDM_HASH_LOG + 1 },
            { :ldm_min_match => ZSTDS::Option::MIN_LDM_MIN_MATCH - 1 },
            { :ldm_min_match => ZSTDS::Option::MAX_LDM_MIN_MATCH + 1 },
            { :ldm_bucket_size_log => ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG - 1 },
            { :ldm_bucket_size_log => ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG + 1 },
            { :ldm_hash_rate_log => ZSTDS::Option::MIN_LDM_HASH_RATE_LOG - 1 },
            { :ldm_hash_rate_log => ZSTDS::Option::MAX_LDM_HASH_RATE_LOG + 1 },
            { :nb_workers => ZSTDS::Option::MIN_NB_WORKERS - 1 },
            { :nb_workers => ZSTDS::Option::MAX_NB_WORKERS + 1 },
            { :job_size => ZSTDS::Option::MIN_JOB_SIZE - 1 },
            { :job_size => ZSTDS::Option::MAX_JOB_SIZE + 1 },
            { :overlap_log => ZSTDS::Option::MIN_OVERLAP_LOG - 1 },
            { :overlap_log => ZSTDS::Option::MAX_OVERLAP_LOG + 1 }
          ],
          (Validation::INVALID_SYMBOLS - [nil]).map do |invalid_symbol|
            { :strategy => invalid_symbol }
          end,
          (Validation::INVALID_INTEGERS - [nil]).flat_map do |invalid_integer|
            [
              { :compression_level => invalid_integer }
            ]
          end,
          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).flat_map do |invalid_integer|
            [
              { :window_log => invalid_integer },
              { :hash_log => invalid_integer },
              { :chain_log => invalid_integer },
              { :search_log => invalid_integer },
              { :min_match => invalid_integer },
              { :target_length => invalid_integer },
              { :ldm_hash_log => invalid_integer },
              { :ldm_min_match => invalid_integer },
              { :ldm_bucket_size_log => invalid_integer },
              { :ldm_hash_rate_log => invalid_integer },
              { :nb_workers => invalid_integer },
              { :job_size => invalid_integer },
              { :overlap_log => invalid_integer }
            ]
          end,
          (Validation::INVALID_BOOLS - [nil]).flat_map do |invalid_bool|
            [
              { :enable_long_distance_matching => invalid_bool },
              { :content_size_flag => invalid_bool },
              { :checksum_flag => invalid_bool },
              { :dict_id_flag => invalid_bool }
            ]
          end
        ]
        .flatten 1
      end

      def self.get_invalid_decompressor_options(buffer_length_names)
        [
          Validation::INVALID_HASHES,
          get_invalid_buffer_length_options(buffer_length_names),
          [
            { :window_log_max => ZSTDS::Option::MIN_WINDOW_LOG_MAX - 1 },
            { :window_log_max => ZSTDS::Option::MAX_WINDOW_LOG_MAX + 1 }
          ],
          (Validation::INVALID_NOT_NEGATIVE_INTEGERS - [nil]).flat_map do |invalid_integer|
            [
              { :window_log_max => invalid_integer }
            ]
          end
        ]
        .flatten 1
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

      COMPRESSION_LEVELS = [
        nil,
        ZSTDS::Option::MIN_COMPRESSION_LEVEL,
        ZSTDS::Option::MAX_COMPRESSION_LEVEL
      ]
      .freeze

      WINDOW_LOGS = [
        nil,
        ZSTDS::Option::MIN_WINDOW_LOG,
        ZSTDS::Option::MAX_WINDOW_LOG
      ]
      .freeze

      HASH_LOGS = [
        nil,
        ZSTDS::Option::MIN_HASH_LOG,
        ZSTDS::Option::MAX_HASH_LOG
      ]
      .freeze

      CHAIN_LOGS = [
        nil,
        ZSTDS::Option::MIN_CHAIN_LOG,
        ZSTDS::Option::MAX_CHAIN_LOG
      ]
      .freeze

      SEARCH_LOGS = [
        nil,
        ZSTDS::Option::MIN_SEARCH_LOG,
        ZSTDS::Option::MAX_SEARCH_LOG
      ]
      .freeze

      MIN_MATCHES = [
        nil,
        ZSTDS::Option::MIN_MIN_MATCH,
        ZSTDS::Option::MAX_MIN_MATCH
      ]
      .freeze

      TARGET_LENGTHS = [
        nil,
        ZSTDS::Option::MIN_TARGET_LENGTH,
        ZSTDS::Option::MAX_TARGET_LENGTH
      ]
      .freeze

      STRATEGIES = (
        [nil] + ZSTDS::Option::STRATEGIES
      )
      .freeze

      # "compression_level" is just a preset for other options.
      # We need to ignore combinations between "compression_level" and these options.

      COMPRESSION_LEVEL_INHERIT_OPTIONS = %i[
        window_log
        hash_log
        chain_log
        search_log
        min_match
        target_length
        strategy
      ]
      .freeze

      LDM_HASH_LOGS = [
        ZSTDS::Option::MIN_LDM_HASH_LOG,
        ZSTDS::Option::MAX_LDM_HASH_LOG
      ]
      .freeze

      LDM_MIN_MATCHES = [
        ZSTDS::Option::MIN_LDM_MIN_MATCH,
        ZSTDS::Option::MAX_LDM_MIN_MATCH
      ]
      .freeze

      LDM_BUCKET_SIZE_LOGS = [
        ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG,
        ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG
      ]
      .freeze

      LDM_HASH_RATE_LOGS = [
        ZSTDS::Option::MIN_LDM_HASH_RATE_LOG,
        ZSTDS::Option::MAX_LDM_HASH_RATE_LOG
      ]
      .freeze

      NB_WORKERS = [
        ZSTDS::Option::MIN_NB_WORKERS,
        ZSTDS::Option::MAX_NB_WORKERS
      ]
      .freeze

      JOB_SIZES = [
        ZSTDS::Option::MIN_JOB_SIZE,
        ZSTDS::Option::MAX_JOB_SIZE
      ]
      .freeze

      OVERLAP_LOGS = [
        ZSTDS::Option::MIN_OVERLAP_LOG,
        ZSTDS::Option::MAX_OVERLAP_LOG
      ]
      .freeze

      WINDOW_LOG_MAXES = [
        ZSTDS::Option::MIN_WINDOW_LOG_MAX,
        ZSTDS::Option::MAX_WINDOW_LOG_MAX
      ]
      .freeze

      private_class_method def self.get_buffer_length_option_data(buffer_length_names)
        buffer_length_names.map do |name|
          BUFFER_LENGTHS.map do |buffer_length|
            { name => buffer_length }
          end
        end
      end

      private_class_method def self.get_compressor_option_data(buffer_length_names)
        [
          get_buffer_length_option_data(buffer_length_names),
          [
            COMPRESSION_LEVELS.map do |compression_level|
              { :compression_level => compression_level }
            end,
            WINDOW_LOGS.map do |window_log|
              { :window_log => window_log }
            end,
            HASH_LOGS.map do |hash_log|
              { :hash_log => hash_log }
            end,
            CHAIN_LOGS.map do |chain_log|
              { :chain_log => chain_log }
            end,
            SEARCH_LOGS.map do |search_log|
              { :search_log => search_log }
            end,
            MIN_MATCHES.map do |min_match|
              { :min_match => min_match }
            end,
            TARGET_LENGTHS.map do |target_length|
              { :target_length => target_length }
            end,
            STRATEGIES.map do |strategy|
              { :strategy => strategy }
            end,
            BOOLS.map do |enable_long_distance_matching|
              { :enable_long_distance_matching => enable_long_distance_matching }
            end,
            LDM_HASH_LOGS.map do |ldm_hash_log|
              { :ldm_hash_log => ldm_hash_log }
            end,
            LDM_MIN_MATCHES.map do |ldm_min_match|
              { :ldm_min_match => ldm_min_match }
            end,
            LDM_BUCKET_SIZE_LOGS.map do |ldm_bucket_size_log|
              { :ldm_bucket_size_log => ldm_bucket_size_log }
            end,
            LDM_HASH_RATE_LOGS.map do |ldm_hash_rate_log|
              { :ldm_hash_rate_log => ldm_hash_rate_log }
            end,
            BOOLS.map do |content_size_flag|
              { :content_size_flag => content_size_flag }
            end,
            BOOLS.map do |checksum_flag|
              { :checksum_flag => checksum_flag }
            end,
            BOOLS.map do |dict_id_flag|
              { :dict_id_flag => dict_id_flag }
            end,
            NB_WORKERS.map do |nb_workers|
              { :nb_workers => nb_workers }
            end,
            JOB_SIZES.map do |job_size|
              { :job_size => job_size }
            end,
            OVERLAP_LOGS.map do |overlap_log|
              { :overlap_log => overlap_log }
            end
          ]
        ]
        .flatten 1
      end

      private_class_method def self.get_decompressor_option_data(buffer_length_names)
        [
          get_buffer_length_option_data(buffer_length_names),
          [
            WINDOW_LOG_MAXES.map do |window_log_max|
              { :window_log_max => window_log_max }
            end
          ]
        ]
        .flatten 1
      end

      private_class_method def self.get_option_combinations(data)
        combinations = data
          .inject([]) do |result, array|
            next array if result.empty?

            result
              .product(array)
              .map(&:flatten)
          end

        combinations.map do |options|
          options.reduce({}, :merge)
        end
      end

      def self.get_compressor_option_combinations(buffer_length_names)
        compressor_option_combinations = get_option_combinations get_compressor_option_data(buffer_length_names)

        compressor_option_combinations.select do |options|
          if options[:compression_level].nil?
            COMPRESSION_LEVEL_INHERIT_OPTIONS.all? { |option| !options[option].nil? }
          else
            COMPRESSION_LEVEL_INHERIT_OPTIONS.all? { |option| options[option].nil? }
          end
        end
      end

      def self.get_compatible_decompressor_options(compressor_options, buffer_length_name_mapping, &_block)
        buffer_length_names              = buffer_length_name_mapping.values
        decompressor_option_combinations = get_option_combinations get_decompressor_option_data(buffer_length_names)

        decompressor_option_combinations.each do |decompressor_options|
          same_buffer_length_values = buffer_length_name_mapping.all? do |compressor_name, decompressor_name|
            decompressor_options[decompressor_name] == compressor_options[compressor_name]
          end

          yield decompressor_options if same_buffer_length_values
        end
      end
    end
  end
end
