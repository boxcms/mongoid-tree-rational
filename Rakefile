#!/usr/bin/env rake
begin
  require 'bundler/setup'
  require "bundler/gem_tasks"
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'yard'

version = File.exist?('VERSION') ? File.read('VERSION') : ""

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

YARD::Rake::YardocTask.new(:doc)

desc "Open an irb session"
task :test_console do
  require 'ap'
  sh "irb -rubygems -I lib -r ./spec/spec_helper.rb"
end

gemspec = eval(File.read("mongoid-tree-rational.gemspec"))
