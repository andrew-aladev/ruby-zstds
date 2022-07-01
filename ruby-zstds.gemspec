# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

lib_path = File.expand_path "lib", __dir__
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include? lib_path

require "zstds/version"

GEMSPEC = Gem::Specification.new do |gem|
  gem.name     = "ruby-zstds"
  gem.summary  = "Ruby bindings for zstd library."
  gem.homepage = "https://github.com/andrew-aladev/ruby-zstds"
  gem.license  = "MIT"
  gem.authors  = File.read("AUTHORS").split("\n").reject(&:empty?)
  gem.email    = "aladjev.andrew@gmail.com"
  gem.version  = ZSTDS::VERSION
  gem.metadata = {
    "rubygems_mfa_required" => "true"
  }

  gem.add_runtime_dependency "adsp", "~> 1.0"
  gem.add_development_dependency "codecov"
  gem.add_development_dependency "json"
  gem.add_development_dependency "minitar", "~> 0.9"
  gem.add_development_dependency "minitest", "~> 5.16"
  gem.add_development_dependency "ocg", "~> 1.4"
  gem.add_development_dependency "parallel"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rake-compiler"
  gem.add_development_dependency "rdoc"
  gem.add_development_dependency "rubocop", "~> 1.31"
  gem.add_development_dependency "rubocop-minitest", "~> 0.20"
  gem.add_development_dependency "rubocop-performance", "~> 1.14"
  gem.add_development_dependency "rubocop-rake", "~> 0.6"
  gem.add_development_dependency "simplecov"

  gem.files =
    `find ext lib -type f \\( -name "*.rb" -o -name "*.h" -o -name "*.c" \\) -print0`.split("\x0") +
    %w[AUTHORS LICENSE README.md]
  gem.require_paths = %w[lib]
  gem.extensions    = %w[ext/extconf.rb]

  gem.required_ruby_version = ">= 2.6"
end
