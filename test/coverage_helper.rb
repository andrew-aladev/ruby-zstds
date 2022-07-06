# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

if ENV["CI"]
  require "codecov"
  require "simplecov"

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Codecov
    ]
  )

  SimpleCov.start do
    track_files "lib/**/*.rb"
  end
end
