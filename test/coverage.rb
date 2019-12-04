# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "codecov"
require "simplecov"

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Codecov
  ]
)

# Workaround for https://bugs.ruby-lang.org/issues/15980
require "coverage"

Coverage.module_eval do
  singleton_class.send :alias_method, :original_start, :start
  def self.start
    original_start :lines => true, :branches => true
  end

  singleton_class.send :alias_method, :original_result, :result
  def self.result
    original_result.transform_values { |coverage| coverage[:lines] }
  end
end

SimpleCov.start do
  add_filter %r{^/test/}
end
