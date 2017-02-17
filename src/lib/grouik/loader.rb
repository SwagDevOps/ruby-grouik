# frozen_string_literal: true

require 'benchmark'
require 'pathname'
require 'ostruct'

require 'grouik/types'

class Grouik::Loader
  attr_accessor :basedir
  attr_accessor :ignores
  attr_reader   :paths
  attr_reader   :pwd
  attr_reader   :attempts
  attr_reader   :errors
  attr_reader   :stats

  def initialize
    self.basedir = '.'
    self.ignores = []

    @pwd       = Pathname.new(Dir.pwd)
    @loadeds   = []
    @errors    = {}
    @loadables = Grouik::Types::LoadablesCollection.new
    @attempts  = 0
    @stats     = nil

    if block_given?
      yield self
      register
    end
  end

  # @param [Array<String|Regexp>] ignores
  def ignores=(ignores)
    @ignores = ignores.to_a.map do |s|
      s.kind_of?(Regexp) ? s : /^#{s}$/
    end
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
    @paths.reverse.each do |path|
      $:.unshift basedir.realpath.join(path).to_s
    end
    self
  end

  # Get loadables
  #
  # @return [Array<Grouik::Loadable>]
  def loadables
    return @loadables.clone unless @loadables.empty?

    loadables = @loadables.clone
    self.basedir do
      @paths.each do |path|
        loaddir = path.to_s
        basereg = /^#{Regexp.quote(loaddir)}\//

        Dir.glob(path.join('**/*.rb'))
          .sort
          .map { |file| file.gsub(basereg, '') }
          .map { |file| Pathname.new(file)}
          .each { |file| loadables.add_file(file, loaddir) }
      end
    end

    @loadables = loadables.filtered_by_regexps(ignores)
    @loadables.clone
  end

  def basedir
    (block_given? ?
       Dir.chdir(pwd.join(basedir)) { yield } :
       Pathname.new(@basedir))
  end

  # @return [self]
  def load_all
    return @loadeds.clone unless @loadeds.empty?

    loadables = self.loadables
    @loadeds  = []
    @errors   = {}

    process_loadables = lambda do |loadables|
      loadables.each_with_index do |loadable, index|
        max = (self.loadables.size ** 2) + 1
        return nil if attempts >= max or loadables.empty?
        @attempts += 1
        loaded = nil
        begin
          loaded = loadable.load(pwd.join(basedir))
        rescue Exception => e
          loadable_path = make_loadable_path(loadable)
          unless @errors[loadable_path]
            @errors[loadable_path] = OpenStruct.new(
              source: loadable_path,
              message: e.message.lines[0].strip.freeze,
              line: e.backtrace[0].split(':')[1],
              error: e
            ).freeze
          end
          next
        end
        unless loaded.nil?
          @loadeds.push(loadables.delete_at(index))
          # when loadable is loaded, then error is removed
          @errors.delete(make_loadable_path(loadable))
        end
      end
      loadables
    end

    @stats = Benchmark.measure do
      while(true)
        loadables = process_loadables.call(loadables)
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
  def format(options={})
    Grouik.get(:formatter).format(load_all.loadables, options).to_s
  end

  def loaded?
    self.loadables.size == @loadeds.size
  end

  protected

  # Make a loadable path
  #
  # @param [Grouik::Loadable] loadable
  # @return [String]
  def make_loadable_path(loadable)
    loadable.path(loadable: true).to_s.freeze
  end
end
