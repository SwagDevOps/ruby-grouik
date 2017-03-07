# frozen_string_literal: true

# Provide ``helpers`` method
module Grouik::Concerns::Helpable
  extend ActiveSupport::Concern

  # Loads helper
  #
  # @param [String] target
  # @return [Grouik::Helpers]
  def helpers
    require 'grouik/helpers'

    Grouik::Helpers
  end
end
