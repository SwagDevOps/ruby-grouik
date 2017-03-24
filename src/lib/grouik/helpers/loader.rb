# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

require 'grouik/types'

# Loader helper, see ``Grouik::Loader``
class Grouik::Helpers::Loader
  class << self
    # Make loadables
    #
    # @@return [Grouik::Types::Loadables]
    def make_loadables
      Grouik::Types::Loadables.new
    end

    # Make ignores
    #
    # @param [Array<String|Regexp>] input
    # @return [Array<Regexp>]
    def make_ignores(input)
      input.to_a.map { |s| s.is_a?(Regexp) ? s : /^#{s}$/ }
    end

    # Register paths
    #
    # @param [String] basedir
    # @param [Array<String|Pathname>] paths
    def register_paths(basedir, paths)
      basedir = Pathname.new(basedir)

      paths.reverse.each do |path|
        $LOAD_PATH.unshift basedir.realpath.join(path).to_s
      end
    end

    # @return [Pathname]
    def pwd
      Pathname.new(Dir.pwd)
    end

    # @param [String] path
    # @return [Array<Pathname>]
    def files_in_path(path)
      loaddir = path.to_s
      basereg = %r{^#{Regexp.quote(loaddir)}\/}

      Dir.glob(path.join('**/*.rb'))
         .sort
         .map { |file| file.gsub(basereg, '') }
         .map { |file| Pathname.new(file) }
    end

    # Collect loadables by paths
    #
    # @param [Array<String>] paths
    # @return [Grouik::Types::Loadables]
    def collect_loadables(paths)
      loadables = self.make_loadables

      paths.each do |path|
        self.files_in_path(path).each do |file|
          loadables = loadables.add_file(file, path.to_s)
        end
      end

      loadables
    end
  end
end
