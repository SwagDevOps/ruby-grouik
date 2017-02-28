# frozen_string_literal: true

module Grouik::Types

end

# Get filtered loadables, using ignores regexp
#
# @return [Array<Grouik::Loadable>]
class Grouik::Types::LoadablesCollection < Array
  def filtered_by_regexps(regexps)
    filter = -> (loadable) do
      regexps.each do |regexp|
        if loadable and regexp.match(loadable.to_s)
          return true
        end
      end
      false
    end

    self.clone.delete_if { |loadable| filter.call(loadable) }
  end

  # @return [self]
  def add_file(file, basedir = nil)
    self.push(make_loadable(basedir, file))
  end

  # @return [Grouik::Loadable]
  def make_loadable(*args)
    Grouik.get(:loadable_factory).call(*args)
  end
end
