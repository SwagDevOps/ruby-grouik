# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

require 'pathname'
require 'active_support/concern'
require 'active_support/inflector'
require 'version_info'

# Provides a standardized way to use ``VersionInfo``
#
# Define ``VERSION_PATH_LEVELS`` in order to suit your needs
module Grouik::Concerns::Versionable
  extend ActiveSupport::Concern

  included do
    VERSION_PATH_LEVELS = 2 unless const_defined?(:VERSION_PATH_LEVELS)
    version_info
  end

  module ClassMethods
    def version_info
      unless const_defined?(:VERSION)
        include VersionInfo

        VersionInfo.file_format = :yaml
        self.VERSION.file_name = version_filepath
        self.VERSION.load
      end

      self.VERSION.to_hash.freeze
    end

    protected

    # Get path to the ``version`` file
    #
    # @return [Pathname]
    def version_filepath
      name = ActiveSupport::Inflector.underscore(self.name)
      dirs = ['..'] * self::VERSION_PATH_LEVELS

      Pathname.new(__dir__).join(*(dirs + [name, 'version_info.yml'])).realpath
    end
  end
end
