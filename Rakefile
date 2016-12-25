require 'rubygems'
require 'pathname'
require 'pp'

spec = Gem::Specification::load('%s/%s.gemspec' % [__dir__, :grouik])
task :default => :gem

task :gem do
  sh('gem', 'build', Pathname.new(spec.loaded_from).basename.to_s)
end
