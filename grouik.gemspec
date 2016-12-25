# gem build grouik.gemspec
# sudo gem install grouik-0.0.1.gem

require 'pathname'

Gem::Specification.new do |s|
  s.name        = Pathname(__FILE__).basename('.*').to_s.freeze
  s.version     = '0.0.1'
  s.licenses    = ['CC-BY-SA-4.0']
  s.bindir      = 'src/bin'
  s.executables = [s.name]
  s.date        = '2016-12-23'
  s.summary     = "Grouik!"
  s.description = "A simple require file generator"
  s.authors     = ["Dimitri Arrigoni"]
  s.email       = 'dimitri@arrigoni.me'
  s.files       = Dir.glob('src/**/**').reject {|i| /\.gem$/.match(i)}
  s.homepage    = 'https://github.com/SwagDevOps/grouik'
end
