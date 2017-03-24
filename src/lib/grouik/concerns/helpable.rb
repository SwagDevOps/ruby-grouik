# frozen_string_literal: true

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
