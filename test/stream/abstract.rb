# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "fcntl"
require "stringio"

require_relative "../common"
require_relative "../minitest"
require_relative "../validation"

module ZSTDS
  module Test
    module Stream
      class Abstract < Minitest::Test
        SOURCE_PATH = Common::SOURCE_PATH

        def test_invalid_initialize
          Validation::INVALID_IOS.each do |invalid_io|
            assert_raises ValidateError do
              target.new invalid_io
            end
          end

          (Validation::INVALID_STRINGS - [nil] + Validation::INVALID_ENCODINGS).each do |invalid_encoding|
            assert_raises ValidateError do
              target.new ::StringIO.new, {}, :external_encoding => invalid_encoding
            end

            assert_raises ValidateError do
              target.new ::StringIO.new, {}, :internal_encoding => invalid_encoding
            end
          end

          (Validation::INVALID_HASHES - [nil]).each do |invalid_hash|
            assert_raises ValidateError do
              target.new ::StringIO.new, {}, :transcode_options => invalid_hash
            end
          end
        end

        def test_invalid_set_encoding
          instance = target.new ::StringIO.new

          (Validation::INVALID_STRINGS - [nil] + Validation::INVALID_ENCODINGS).each do |invalid_encoding|
            assert_raises ValidateError do
              instance.set_encoding invalid_encoding
            end

            assert_raises ValidateError do
              instance.set_encoding ::Encoding::BINARY, invalid_encoding
            end
          end

          Validation::INVALID_ENCODINGS.each do |invalid_encoding|
            assert_raises ValidateError do
              instance.set_encoding "#{::Encoding::BINARY}:#{invalid_encoding}"
            end

            assert_raises ValidateError do
              instance.set_encoding "#{invalid_encoding}:#{::Encoding::BINARY}"
            end
          end

          (Validation::INVALID_HASHES - [nil]).each do |invalid_hash|
            assert_raises ValidateError do
              instance.set_encoding ::Encoding::BINARY, ::Encoding::BINARY, invalid_hash
            end

            assert_raises ValidateError do
              instance.set_encoding "#{::Encoding::BINARY}:#{::Encoding::BINARY}", invalid_hash
            end
          end
        end

        def test_to_io
          instance = target.new ::StringIO.new
          assert_equal instance, instance.to_io
        end

        def test_io_delegates
          ::File.open SOURCE_PATH, "wb+" do |file|
            instance = target.new file

            instance.autoclose = true
            assert_predicate instance, :autoclose?

            instance.binmode
            assert_predicate instance, :binmode

            instance.close_on_exec = true
            assert_predicate instance, :close_on_exec?

            # Fcntl is not available on windows.
            if Fcntl.const_defined? :F_GETFL
              stats = instance.fcntl Fcntl::F_GETFL, 0
              refute_nil stats
            end

            instance.fdatasync

            fd = instance.fileno
            refute_nil fd

            refute_predicate instance, :isatty
            assert_nil instance.pid

            instance.sync = true
            assert_predicate instance, :sync

            refute_nil instance.to_i
            refute_predicate instance, :tty?
          end
        end

        def test_stat
          instance = target.new $stdout

          refute_predicate instance.stat, :file?
          refute_predicate instance.stat, :pipe?
          refute_predicate instance.stat, :socket?
        end

        # -----

        protected def target
          self.class::Target
        end
      end
    end
  end
end
