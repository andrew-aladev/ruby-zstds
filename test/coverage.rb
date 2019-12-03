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
SimpleCov.module_eval do |mod|
  def mod.start(profile = nil, &block)
    require "coverage"

    load_profile profile if profile
    configure(&block) if block_given?

    @result  = nil
    @running = true
    @pid     = Process.pid

    Coverage.start :lines => true, :branches => true
  end
end

SimpleCov.start do
  add_filter %r{^/test/}
end
