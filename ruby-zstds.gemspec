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

  gem.files =
    `find ext lib -type f \\( -name "*.rb" -o -name "*.h" -o -name "*.c" \\) -print0`.split("\x0") +
    %w[AUTHORS LICENSE README.md]
  gem.require_paths = %w[lib]
  gem.extensions    = %w[ext/extconf.rb]

  gem.required_ruby_version = ">= 2.6"
end
