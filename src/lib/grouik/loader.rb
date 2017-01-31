# frozen_string_literal: true

require 'benchmark'
require 'pathname'

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
    @loadables = []
    @attempts  = 0
    @stats     = nil

    if block_given?
      yield self
      register
    end
  end

  # @param [Array<String>] ignores
  def ignores=(ignores)
    @ignores = ignores.to_a.map { |s| /#{s}/ }
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

    loadables = []
    self.basedir do
      @paths.each do |path|
        base = path.to_s
        Dir.glob(path.join('**/*.rb'))
          .sort
          .map { |file| file.gsub(/^#{Regexp.quote(base)}\//, '') }
          .map { |file| Pathname.new(file)}
          .each { |file| loadables << make_loadable(base, file) }
      end
    end

    (@loadables = loadables).clone
  end

  # Get filtered loadables, using ignores regexp
  #
  # @return [Array<Grouik::Loadable>]
  def filtered
    loadables = self.loadables.clone
    filter = -> (loadable) do
      ignores.each do |regex|
        if loadable and regex.match(loadable.path(loadable: true).to_s)
          return true
        end
      end
      false
    end

    loadables.delete_if { |loadable| filter.call(loadable) }
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
          @errors[loadable.path.to_s] = e unless @errors[loadable.path.to_s]
          next
        end
        @loadeds.push(loadables.delete_at(index)) unless loaded.nil?
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
    Grouik.get(:formatter).format(load_all.filtered, options).to_s
  end

  def loaded?
    self.loadables.size == @loadeds.size
  end

  protected

  def make_loadable(*args)
    Grouik.get(:loadable_factory).call(*args)
  end
end
