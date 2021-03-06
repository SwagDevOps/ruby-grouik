# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

require 'active_support/concern'

# Provide ``helpers`` method
module Grouik::Concerns::Helpable
  extend ActiveSupport::Concern

  # Loads helper
  #
  # @return [Grouik::Helpers]
  def helpers
    Grouik.get(:helpers)
  end
end
