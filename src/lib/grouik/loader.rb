# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

require 'benchmark'
require 'pathname'
require 'ostruct'

require 'grouik/concerns'

# Main class loader
#
# loads files during ``Grouik::Loader#load_all``
class Grouik::Loader
  attr_accessor :basedir
  attr_accessor :ignores
  attr_reader   :paths

  attr_reader   :attempts
  attr_reader   :errors
  attr_reader   :stats

  include Grouik::Concerns::Helpable

  def initialize
    self.basedir = '.'
    self.ignores = []

    @loadeds   = []
    @errors    = {}
    @loadables = []
    @attempts  = 0
    @stats     = nil

    return self unless block_given?

    yield self
    register
  end

  # @param [Array<String|Regexp>] ignores
  def ignores=(ignores)
    @ignores = helpers.get(:loader).make_ignores(ignores)
  end

  # @param [Array<String>] paths
  def paths=(paths)
    @paths = paths.to_a.map { |path| Pathname.new(path.to_s) }
  end

  # @return [Array<Pathname>]
  def paths
    (@paths || (@paths.empty? ? ['.'] : @paths)).clone
  end

  # Register paths
  #
  # @return [self]
  def register
    helpers.get(:loader).register_paths(basedir, @paths)

    self
  end

  # Get loadables
  #
  # @return [Array<Grouik::Loadable>]
  def loadables
    if @loadables.empty?
      self.basedir do
        @loadables = helpers.get(:loader)
                            .collect_loadables(paths)
                            .ignores(ignores)
      end
    end

    @loadables.clone
  end

  # @return [Pathname]
  def basedir
    Dir.chdir(helpers.get(:loader).pwd.join(basedir)) { yield } if block_given?

    Pathname.new(@basedir)
  end

  # @return [self]
  def load_all
    return @loadeds.clone unless @loadeds.empty?

    loadables = self.loadables
    @loadeds  = []
    @errors   = {}

    @stats = Benchmark.measure do
      loop do
        loadables = process_loadables(loadables)
        break if loadables.nil? or (loadables and loadables.empty?)
      end
    end
    @loadeds.compact
    self
  end

  # Format using a formatter
  #
  # @param [Hash] options
  # @return [String]
  def format(options = {})
    Grouik.get(:formatter).format(load_all.loadables, options).to_s
  end

  def loaded?
    self.loadables.size == @loadeds.size
  end

  # @return [Fixnum]
  def attempts_maxcount
    (self.loadables.size**2) + 1
  end

  protected

  def process_loadables(processables)
    processables.each_with_index do |loadable, index|
      return [] if attempts >= attempts_maxcount or processables.empty?

      @attempts += 1
      loaded = nil
      begin
        loaded = loadable.load(helpers.get(:loader).pwd.join(basedir))
      rescue StandardError => e
        unless @errors[loadable.to_s]
          @errors[loadable.to_s] = OpenStruct.new(
            source: loadable.to_s,
            message: e.message.lines[0].strip.freeze,
            line: e.backtrace[0].split(':')[1],
            error: e
          ).freeze
        end
        next
      end

      next if loaded.nil?

      @loadeds.push(processables.delete_at(index))
      # when loadable is loaded, then error is removed
      @errors.delete(loadable.to_s)
    end
    processables
  end
end
