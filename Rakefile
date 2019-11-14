require "rake/extensiontask"
require "rake/testtask"
require "rubygems/package_task"

load "ruby-zstds.gemspec"

Rake::ExtensionTask.new do |ext|
  ext.name           = "zstds_ext"
  ext.ext_dir        = "ext"
  ext.lib_dir        = "lib"
  ext.tmp_dir        = "tmp"
  ext.source_pattern = "*.{c,h}"
end

Rake::TestTask.new do |task|
  task.libs << %w[lib]

  pathes          = `find test | grep "\.test\.rb$"`
  task.test_files = pathes.split "\n"
end

task :default => %i[compile test]

Gem::PackageTask.new(GEMSPEC).define
