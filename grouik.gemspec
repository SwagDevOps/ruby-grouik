# frozen_string_literal: true
# vim: ai ts=2 sts=2 et sw=2 ft=ruby

require '%s/src/lib/grouik' % __dir__

Gem::Specification.new do |s|
  s.name        = File.basename(__FILE__).split('.')[0]
  s.version     = Grouik::VERSION
  s.date        = Grouik::RELEASE_DATE
  s.summary     = 'Grouik!'
  s.description = 'A simple require file generator'

  s.licenses    = ['CC-BY-SA-4.0']
  s.authors     = ['Dimitri Arrigoni']
  s.email       = 'dimitri@arrigoni.me'
  s.homepage    = 'https://github.com/SwagDevOps/ruby-grouik'

  s.require_paths = ['src/lib']
  s.bindir        = 'src/bin'
  s.executables   = [s.name]
  s.files         = Dir.glob('src/**/**.rb') + \
                    Dir.glob('src/**/VERSION')

  s.add_runtime_dependency "activesupport", ["~> 5.0"]
  s.add_runtime_dependency "tenjin", ["~> 0.7"]
  s.add_runtime_dependency "rainbow", ["~> 2.2"]
  s.add_development_dependency "rake", ["~> 11.3"]
  s.add_development_dependency "cliver", ["= 0.3.2"]
  s.add_development_dependency "gemspec_deps_gen", ["= 1.1.2"]
  s.add_development_dependency "yard", ["~> 0.9"]
  s.add_development_dependency "redcarpet", ["~> 3.4"]
  s.add_development_dependency "github-markup", ["~> 1.4"]
end

# Local Variables:
# mode: ruby
# End: