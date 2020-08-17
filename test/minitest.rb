# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "minitest"
require "minitest/autorun"

module Minitest
  Minitest.module_eval do
    class << self
      def <<(klass)
        Runnable.runnables << klass unless Runnable.runnables.include? klass
        nil
      end
    end
  end

  Runnable.instance_eval do
    def self.inherited(_klass); end # rubocop:disable Lint/MissingSuper
  end
end
