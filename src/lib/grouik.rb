# -*- coding: utf-8 -*-

require 'pathname'
# loads sub(modules|classes) -----------------------------------------
[:version, :loadable].each do |r|
  require '%s/grouik/%s' % [__dir__, r]
end

class Grouik
  attr_accessor :basedir
  attr_accessor :ignores
  attr_reader   :paths
  attr_reader   :pwd
  attr_reader   :attempts
  attr_reader   :errors
  attr_reader   :stats

  def initialize(*paths)
    self.paths = paths.empty? ? ['.'] : paths
    self.basedir = '.'
    self.ignores = []

    @pwd       = Pathname.new(Dir.pwd)
    @loadeds   = []
    @errors    = {}
    @loadables = []
    @attempts  = 0
    @stats     = nil

    yield self if block_given?
  end

  def ignores
    @ignores.map {|i| i = /\.rb$/.match(i) ? i : '%s.rb' % i}
  end

  def paths=(paths)
    @paths = paths.map { |path| Pathname.new(path.to_s) }
  end

  def loadables
    if @loadables.empty?
      loadables = []
      self.basedir do
        @paths.each do |path|
          base = path.to_s
          Dir.glob(path.join('**/*.rb'))
            .sort
            .map { |file| file.gsub(/^#{Regexp.quote(base)}\//, '') }
            .map { |file| Pathname.new(file)}
            .each { |file| loadables.push(Loadable.new(base, file)) }
        end
      end

      loadables.reject! do |loadable|
        self.ignores.include?(loadable.path.to_s)
      end
      @loadables = loadables
    end
    @loadables.clone
  end

  def basedir
    (block_given? ?
       Dir.chdir(pwd.join(basedir)) { yield } :
       Pathname.new(@basedir))
  end

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
      return loadables
    end

    @stats = Benchmark.measure do
      while(true)
        loadables = process_loadables.call(loadables)
        break if loadables.nil? or (loadables and loadables.empty?)
      end
    end
    @loadeds.compact
  end

  def loaded?
    self.loadables.size == @loadeds.size
  end

  def display_errors
    errors.each do |file, error|
      STDERR.puts('%s: %s' % [file, error.message])
    end
    self
  end

  def display_status
    message = '%s: %s files; %s iterations; %s errors (%.4f)'
    statuses = {true  => 'success',
                false => 'failure',}

    STDERR.puts((message % \
                [
                  statuses.fetch(self.loaded?),
                  loadables.size,
                  attempts,
                  errors.size,
                  stats ? stats.real : 0
                ]).capitalize)
  end
end
