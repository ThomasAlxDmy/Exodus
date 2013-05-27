#!/usr/bin/env rake
require 'rubygems'
require 'rake'

require 'rspec/core/rake_task'

FileList.new(File.dirname(__FILE__) + '/tasks/*.rake').each { |file| import file }

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["-c", "-f progress"]
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec
