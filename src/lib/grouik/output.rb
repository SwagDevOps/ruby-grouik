# frozen_string_literal: true

module Grouik::Output
  [:message].each do |req|
    require '%s/output/%s' % [__dir__, req]
  end
end
