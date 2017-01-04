# frozen_string_literal: true
require '%s/src/lib/grouik' % __dir__

Gem::Specification.new do |s|
  s.name        = File.basename(__FILE__).split('.')[0]
  s.version     = Grouik::VERSION
  s.summary     = 'Grouik!'
  s.description = 'A simple require file generator'
  s.date        = '2016-12-23'

  s.licenses    = ['CC-BY-SA-4.0']
  s.authors     = ['Dimitri Arrigoni']
  s.email       = 'dimitri@arrigoni.me'
  s.homepage    = '%s://github.com/%s/%s' % [:https, 'SwagDevOps', s.name]

  s.require_paths = ['src/lib']
  s.bindir        = 'src/bin'
  s.executables   = [s.name]
  s.files         = Dir.glob('src/**/**').reject do |i|
    /^.+\.gemspec\.erb$/.match(i)
  end

  s.add_runtime_dependency "activesupport", ["~> 5.0"]
  s.add_development_dependency "rake", ["~> 11.3"]
  s.add_development_dependency "cliver", ["= 0.3.2"]
  s.add_development_dependency "gemspec_deps_gen", ["= 1.1.2"]
end

# Local Variables:
# mode: ruby
# End: