require 'pathname'
require 'pp'
require 'rubygems'

class Project
  class << self
    def name
      :grouik
    end

    def spec
      Gem::Specification::load('%s/%s.gemspec' % [__dir__, name])
    end
  end
end

Dir.glob('rake/**.rake').each {|f| load(f)}
