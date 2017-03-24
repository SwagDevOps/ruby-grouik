# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

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
      class_name = self.classify(target)

      require load_dir.join(target.to_s) unless const_defined?(class_name)

      inflector.constantize(class_name)
    end

    # Directory where helpers stand
    #
    # @return [Pathname]
    def load_dir
      Pathname.new(__FILE__.gsub(/\.rb$/, ''))
    end

    protected

    # @return ActiveSupport::Inflector
    def inflector
      ActiveSupport::Inflector
    end

    # Transform string
    #
    # return [String]
    def classify(target)
      '%s::%s' % [name, inflector.classify(target.to_s.gsub('/', '::'))]
    end
  end
end
