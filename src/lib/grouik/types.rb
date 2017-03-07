# frozen_string_literal: true

# Special types in use
module Grouik::Types
end

# Get filtered loadables, using ignores regexp
#
# @return [Array<Grouik::Loadable>]
class Grouik::Types::Loadables < Array
  # Removes ignored patterns (regexps)
  #
  # @param [Array<Regexp>] regexps
  # @return [self]
  def ignores(regexps)
    filter = lambda do |loadable, regexps|
      regexps.each do |regexp|
        return true if loadable and regexp.match(loadable.to_s)
      end

      false
    end

    self.clone.delete_if do |loadable|
      filter.call(loadable, regexps)
    end
  end

  # @return [self]
  def add_file(file, basedir = nil)
    self.push(make_loadable(basedir, file))

    self
  end

  # @return [Grouik::Loadable]
  def make_loadable(*args)
    Grouik.get(:loadable_factory).call(*args)
  end
end
