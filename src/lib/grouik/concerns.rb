# frozen_string_literal: true

# Concerns in use
module Grouik::Concerns
  require 'active_support/concern'

  [:helpable].each do |concern|
    require 'grouik/concerns/%s' % concern
  end
end
