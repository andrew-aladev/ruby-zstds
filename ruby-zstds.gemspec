# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

lib_path = File.expand_path "lib", __dir__
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include? lib_path

require "date"
require "zstds/version"

GEMSPEC = Gem::Specification.new do |gem|
  gem.name     = "ruby-zstds"
  gem.summary  = "Ruby bindings for zstd library."
  gem.homepage = "https://github.com/andrew-aladev/ruby-zstds"
  gem.license  = "MIT"
  gem.authors  = File.read("AUTHORS").split("\n").reject(&:empty?)
  gem.email    = "aladjev.andrew@gmail.com"
  gem.version  = ZSTDS::VERSION
  gem.date     = Date.today.to_s

  gem.add_development_dependency "codecov"
  gem.add_development_dependency "minitar", "~> 0.9"
  gem.add_development_dependency "minitest", "~> 5.14"
  gem.add_development_dependency "ocg", "~> 1.3"
  gem.add_development_dependency "parallel"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rake-compiler"
  gem.add_development_dependency "rubocop", "~> 1.8"
  gem.add_development_dependency "rubocop-minitest", "~> 0.10"
  gem.add_development_dependency "rubocop-performance", "~> 1.9"
  gem.add_development_dependency "rubocop-rake", "~> 0.5"
  gem.add_development_dependency "simplecov"

  gem.files =
    `git ls-files -z --directory {ext,lib}`.split("\x0") +
    %w[AUTHORS LICENSE README.md]
  gem.require_paths = %w[lib]
  gem.extensions    = %w[ext/extconf.rb]

  gem.required_ruby_version = ">= 2.5"
end
