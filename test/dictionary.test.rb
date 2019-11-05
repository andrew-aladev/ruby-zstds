# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds/dictionary"

require_relative "common"
require_relative "minitest"
require_relative "option"
require_relative "validation"

module ZSTDS
  module Test
    class Dictionary < Minitest::Unit::TestCase
      Target = ZSTDS::Dictionary

      TEXTS       = Common::TEXTS
      LARGE_TEXTS = Common::LARGE_TEXTS

      SAMPLES = Common.generate_texts(
        ::SecureRandom.random_bytes(1 << 10), # 1 KB
        ::SecureRandom.random_bytes(1 << 12), # 4 KB
        ::SecureRandom.random_bytes(1 << 14), # 16 KB
        ::SecureRandom.random_bytes(1 << 16), # 64 KB
        ::SecureRandom.random_bytes(1 << 18)  # 256 KB
      )
      .shuffle
      .freeze

      CAPACITIES = [
        0,
        1 << 12 # 4 KB
      ]
      .freeze

      def test_invalid_arguments
        Validation::INVALID_ARRAYS.each do |invalid_samples|
          assert_raises ValidateError do
            Target.new invalid_samples
          end
        end

        Validation::INVALID_STRINGS.each do |invalid_sample|
          assert_raises ValidateError do
            Target.new [invalid_sample]
          end
        end

        assert_raises ValidateError do
          Target.new [""]
        end

        Validation::INVALID_NOT_NEGATIVE_INTEGERS.each do |invalid_capacity|
          assert_raises ValidateError do
            Target.new ["123"], :capacity => invalid_capacity
          end
        end
      end

      def test_texts
        CAPACITIES.each do |capacity|
          dictionary = Target.new SAMPLES, :capacity => capacity
        end
      end

      def test_large_texts
        CAPACITIES.each do |capacity|
          # dictionary = Target.new SAMPLES, :capacity => capacity
        end
      end
    end

    Minitest << Dictionary
  end
end
