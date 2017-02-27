require 'rubygems'
require 'bundler/setup'
require 'active_support/inflector'

class Project
  class << self
    # @return [Symbol]
    def name
      :grouik
    end

    # Main class (subject of project)
    #
    # @return [Class]
    def subject
      require '%s/src/lib/%s' % [Dir.pwd, Project.name]

      inflector.constantize(inflector.classify(name))
    end

    # Gem specification
    #
    # @return [Gem::Specification]
    def spec
      Gem::Specification::load('%s/%s.gemspec' % [__dir__, name])
    end

    # @return [Hash]
    def version_info
      ({version: subject.VERSION.to_s}.merge(subject.version_info)).freeze
    end

    protected

    # @return [ActiveSupport::Inflector]
    def inflector
      ActiveSupport::Inflector
    end
  end
end

Dir.glob('rake/**/*.rake').each {|f| load(f)}
