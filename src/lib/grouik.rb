# frozen_string_literal: true

require 'pathname'
require 'pp'
require 'active_support/inflector'
$:.unshift Pathname.new(__dir__)

module Grouik
  VERSION = Pathname.new(__dir__)
              .join(ActiveSupport::Inflector.underscore(name), 'VERSION')
              .read
              .strip

  # loads sub(modules|classes)
  [:loader, :loadable, :formatter, :process].each do |r|
    require '%s/%s' % [ActiveSupport::Inflector.underscore(name), r]
  end

  # dependency injection
  @components = {
    process: Process,
    formatter: Formatter,
    loadable_factory: -> (base, path) { Loadable.new(base, path) },
  }

  class << self
    attr_accessor :components

    def get(name)
      components.fetch(name.to_sym)
    end
  end
end
