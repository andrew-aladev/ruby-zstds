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
          assert_equal instance.to_io, instance
        end

        def test_io_delegates
          ::File.open SOURCE_PATH do |file|
            instance = target.new file

            instance.autoclose = true
            assert instance.autoclose?

            instance.binmode
            assert instance.binmode

            instance.close_on_exec = true
            assert instance.close_on_exec?

            stats = instance.fcntl Fcntl::F_GETFL, 0
            refute stats.nil?

            instance.fdatasync

            fd = instance.fileno
            refute fd.nil?

            refute instance.isatty
            assert instance.pid.nil?

            instance.sync = true
            assert instance.sync

            refute instance.to_i.nil?
            refute instance.tty?
          end
        end

        def test_stat
          instance = target.new ::STDOUT

          refute instance.stat.file?
          refute instance.stat.pipe?
          refute instance.stat.socket?
        end

        # -----

        protected def target
          self.class::Target
        end
      end
    end
  end
end
