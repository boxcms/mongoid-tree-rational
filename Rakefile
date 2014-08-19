#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

version = File.exist?('VERSION') ? File.read('VERSION') : ""

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "mongoid-tree-rational"
  gem.version     = version
  gem.homepage    = "https://github.com/boxcms/mongoid-tree-rational"
  gem.license     = "MIT"
  gem.summary     = %Q{A tree structure for Mongoid documents with rational numbers}
  gem.description = %Q{A tree structure for Mongoid documents using the materialized path pattern and rational number sorting.}
  gem.email       = "leifcr@gmail.com"
  gem.authors     = ['Leif Ringstad', 'Benedikt Deicke']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

# RDoc::Task.new(:rdoc) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = "Mongoid Tree Rational #{version}"
#   rdoc.options << '--line-numbers'
#   rdoc.rdoc_files.include('README.rdoc')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

# Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

# YARD::Rake::YardocTask.new(:doc)

desc "Open an irb session"
task :test_console do
  require 'ap'
  sh "irb -rubygems -I lib -r ./spec/spec_helper.rb"
end