# gem build grouik.gemspec
# sudo gem install grouik-0.0.1.gem
#
# sudo gem install specific_install
# sudo gem specific_install -l <url to a github gem>
#
# gem-path gem can find the installation path of a particular gem:
# sudo gem install gem-path
# gem path rails
# gem path rails '< 4'

require 'pathname'

Gem::Specification.new do |s|
  s.name        = Pathname.new(__FILE__).basename('.*').to_s.freeze
  s.version     = '0.0.1'
  s.licenses    = ['CC-BY-SA-4.0']
  s.bindir      = 'src/bin'
  s.executables = [s.name]
  s.date        = '2016-12-23'
  s.summary     = 'Grouik!'
  s.description = 'A simple require file generator'
  s.authors     = ['Dimitri Arrigoni']
  s.email       = 'dimitri@arrigoni.me'
  s.files       = (Dir.glob('src/**/**')
                     .reject { |i| /^.+\.gemspec\.erb$/.match(i) })
  s.require_paths = ['src/lib']
  s.homepage    = ('%s://github.com/SwagDevOps/' % [:https, s.name]).freeze
end

# Local Variables:
# mode: ruby
# End: