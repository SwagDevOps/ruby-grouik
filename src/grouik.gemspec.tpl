# frozen_string_literal: true
# vim: ai ts=2 sts=2 et sw=2 ft=ruby

Gem::Specification.new do |s|
  s.name        = '#{@name}'
  s.version     = '#{@version}'
  s.date        = '#{@date}'
  s.summary     = '#{@summary}'
  s.description = '#{@description}'

  s.licenses    = #{@licenses}
  s.authors     = #{@authors}
  s.email       = '#{@email}'
  s.homepage    = '#{@homepage}'

  s.require_paths = ['src/lib']
  s.bindir        = 'src/bin'
  s.executables   = ['#{@name}']
  s.files         = Dir.glob('src/**/**.rb') + \
                    Dir.glob('src/**/version_info.yml')

  #{@dependencies}
end

# Local Variables:
# mode: ruby
# End: