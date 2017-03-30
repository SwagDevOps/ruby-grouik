# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

require 'pathname'
require 'active_support/inflector'

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
  require 'grouik/concerns'

  include Concerns::Versionable

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
