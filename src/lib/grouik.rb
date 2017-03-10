# frozen_string_literal: true

require 'pathname'
require 'active_support/inflector'
require 'version_info'

$LOAD_PATH.unshift Pathname.new(__dir__)

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
  require 'grouik/helpers'

  class << self
    # @return [Hash]
    def version_info
      unless self.const_defined?(:VERSION)
        include VersionInfo

        VersionInfo.file_format = :yaml
        VERSION.file_name = self.version_filepath
        VERSION.load
      end

      VERSION.to_hash.freeze
    end

    protected

    # Get path to the ``version`` file
    #
    # @return [Pathname]
    def version_filepath
      name = ActiveSupport::Inflector.underscore(self.name)

      Pathname.new(__dir__).join(name, 'version_info.yml')
    end
  end

  # registers version_info
  self.version_info
  # loads sub(modules|classes)
  [:loader, :loadable, :formatter, :process, :output].each do |r|
    require '%s/%s' % [ActiveSupport::Inflector.underscore(name), r]
  end

  @components = {
    process_class: Process,
    formatter: Formatter,
    helpers: Grouik::Helpers,
    inflector: ActiveSupport::Inflector,
    messager_factory: ->(&block) { Output::Message.new(&block) },
    loadable_factory: ->(base, path) { Loadable.new(base, path) },
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
