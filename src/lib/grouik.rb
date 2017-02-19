# frozen_string_literal: true

require 'pathname'
require 'active_support/inflector'

$:.unshift Pathname.new(__dir__)

# Produce a ``require`` file, resolving classes dependencies
#
# Sample of use:
#
# ~~~~
# Grouik.process do |process|
#      process.basedir   = './path/to/my/project'
#      process.paths     = ['lib']
#      process.ignores   = []
#      process.output    = '/dev/stdout'
#      process.template  = 'lib/main'
#      process.bootstrap = nil
#      process.verbose   = true
# end.success? ? 0 : 1
# ~~~~
#
# or using command line.
module Grouik
  class << self
    protected

    # Get path to the ``VERSION`` file
    #
    # @return [Pathname]
    def version_filepath
      name = ActiveSupport::Inflector.underscore(self.name)

      Pathname.new(__dir__).join(name, 'VERSION')
    end
  end

  # Version
  #
  # @return [String]
  VERSION = self.version_filepath.read.strip

  # Release date
  #
  # @return [String]
  RELEASE_DATE = File.mtime(self.version_filepath).strftime('%Y-%m-%d')

  # loads sub(modules|classes)
  [:loader, :loadable, :formatter, :process, :output].each do |r|
    require '%s/%s' % [ActiveSupport::Inflector.underscore(name), r]
  end

  @components = {
    process_class: Process,
    formatter: Formatter,
    messager_factory: -> (&block) { Output::Message.new(&block) },
    loadable_factory: -> (base, path) { Loadable.new(base, path) },
  }

  class << self
    attr_accessor :components

    # Access to components
    #
    # @param name [String, Symbol] name of component
    # @return [Object]
    # @see Grouik.components
    def get(name)
      components.fetch(name.to_sym)
    end

    # Initialize a Process and process it
    #
    # @return [Grouik::Process]
    def process(&block)
      self.get(:process_class).new(&block).process
    end

    def message(&block)
      self.get(:messager_factory).call(&block).send
      self
    end
  end
end
