# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

# Concerns in use
module Grouik::Concerns
  require 'active_support/concern'

  [:helpable, :versionable].each do |concern|
    require 'grouik/concerns/%s' % concern
  end
end
