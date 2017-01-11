# frozen_string_literal: true

require 'pathname'
require 'pp'
require 'active_support/inflector'
$:.unshift Pathname.new(__dir__)

# Produce a ``require`` file, resolving classes dependencies
#
# Sample of use:
#
# ~~~~
# Grouik.process do |gr|
#      gr.basedir   = './path/to/my/project'
#      gr.paths     = ['lib']
#      gr.ignores   = []
#      gr.output    = '/dev/stdout'
#      gr.template  = 'lib/main'
#      gr.bootstrap = nil
#      gr.verbose   = true
# end.success? ? 0 : 1
# ~~~~
#
# or using command line.
module Grouik
  # Version
  VERSION = Pathname.new(__dir__)
              .join(ActiveSupport::Inflector.underscore(name), 'VERSION')
              .read
              .strip

  # loads sub(modules|classes)
  [:loader, :loadable, :formatter, :process].each do |r|
    require '%s/%s' % [ActiveSupport::Inflector.underscore(name), r]
  end

  @components = {
    process_class: Process,
    formatter: Formatter,
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
  end
end
