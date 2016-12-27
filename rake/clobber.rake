# www.virtuouscode.com/2014/04/28/rake-part-6-clean-and-clobber/
require 'rake/clean'

[
  'pkg',
  "#{Project.name}.gemspec",
].each { |c| CLOBBER.include(c) }
