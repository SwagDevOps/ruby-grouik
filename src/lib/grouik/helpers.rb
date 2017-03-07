# frozen_string_literal: true

require 'pathname'
require 'active_support/inflector'

# Helpers (loader)
#
# Provide easy access to helpers
module Grouik::Helpers
  class << self
    # Retrieve helper by name
    #
    # @param [String|Symbol] target
    # @return [Object]
    def get(target)
      inflector = ActiveSupport::Inflector
      class_name = [
        name,
        inflector.classify(target.to_s.gsub('/', '::'))
      ].join('::')

      require '%s/%s' % [__FILE__.gsub(/\.rb$/, ''), target]

      inflector.constantize(class_name)
    end
  end
end
