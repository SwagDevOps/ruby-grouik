#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pathname'
require 'yaml'
require 'benchmark'
require 'pp'

class Grouik
  class Loadable
  end

  class Cli
  end
end

class Grouik::Cli
  attr_reader :argv
  attr_reader :options
  attr_reader :arguments

  class << self
    def program_name
      Pathname.new($0).basename('.rb').to_s
    end

    def run(argv = ARGV)
      self.new(argv).run
    end

    # default options
    def defaults
      {
        verbose: true,
        paths: ['.'],
        basedir: '.',
        prefix: nil,
        output: STDOUT,
        ignores: [],
        require: nil,
      }
    end
  end

  def program_name
    self.class.program_name
  end

  def initialize(argv = ARGV)
    @argv = argv.clone
    @options = self.class.defaults
    @options = config unless config.empty?
    @arguments = []
  end

  def parser
    options = @options
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: %s [options]' % self.program_name
      opts.on('--basedir=BASEDIR', 'Basedir [%s]' % options[:basedir]) \
      {|v| options[:basedir] = v}
      opts.on('--prefix=PREFIX', 'Prefix added on paths' ) \
      {|v| options[:prefix] = v}
      opts.on('-o=OUTPUT', '--output=OUTPUT', 'Output [/dev/stdout]') do |v|
        options[:output] = v
      end
      opts.on('-r=REQUIRE', '--require=REQUIRE', 'Required file on startup') do |v|
        options[:require] = v
      end

      opts.on('--ignores x,y,z', Array, 'Ignores') \
      {|v| options[:ignores] = v}
      opts.on('--paths x,y,z', Array, 'Paths') \
      {|v| options[:paths] = v}
      opts.on('-v', '--[no-]verbose', 'Run verbosely') \
      {|v| options[:verbose] = v}
    end

    parser
  end

  def parse!
    argv = self.argv.clone
    begin
      parser.parse!(argv)
    rescue OptionParser::InvalidOption
      STDERR.puts(parser)
      exit(Errno::EINVAL::Errno)
    end
    @arguments = argv
    @options = prepare_options(@options)
    self
  end

  def run
    parse!
    if ARGV.empty? and config.empty?
      STDERR.puts(parser)
      STDERR.puts("\nCan not run without arguments and empty config.")
      exit(Errno::EINVAL::Errno)
    end

    gen = Grouik.new(*options.fetch(:paths)) do |instance|
      instance.basedir = options.fetch(:basedir)
      instance.ignores = options.fetch(:ignores)
    end

    if options.fetch(:output).respond_to?(:file?)
      options[:output].write('')
    end

    begin
      require options[:require] if options[:require]
    rescue NameError
    rescue LoadError
    end

    content = make_require_from_loadables(gen.load_all)
    options.fetch(:output).write(content)

    gen.display_errors
    if options[:verbose]
      STDERR.write("\n") unless gen.errors.empty?
      gen.display_status
    end

    return gen.loaded? ? 0 : 1
  end

  def config
    file = Pathname.new(Dir.pwd).join('%s.yml' % self.program_name)
    if file.exist? and file.file?
      h = YAML.load(file.read).inject({}){|h,(k,v)| h[k.intern] = v; h}
      h.each do |k, v|

      end
      return h
    end
    {}
  end

  protected

  def prepare_options(options)
    [:require, :output].each do |k|
      next unless options[k]
      begin
        options[k] = Pathname.new(options[k])
      rescue TypeError
        next
      end
      unless options[k].absolute?
        options[k] = Pathname.new(Dir.pwd).join(options[k])
      end
    end
    [:ignores, :paths].each do |k|
      next unless options[k]
      options[k] = [options[k]] if options[k].is_a? String
    end
    options
  end

  def make_require_from_loadables(loadables)
    lines = ['[']
    prefix = options[:prefix]
    if prefix
      prefix = '%s/' % prefix unless /\//.match(prefix)
    end
    loadables
      .map {|i| '%s\'%s%s\',' % [' '*2, prefix, i.path.to_s.gsub(/\.rb$/, '')]}
      .each {|line| lines.push(line)}
    lines += ['].each do |path|',
              (' '*2)+'require \'%s/%s\' % [__dir__, path]',
              'end']
    "%s\n" % lines.join("\n")
  end
end

class Grouik::Loadable
  attr_reader :base
  attr_reader :path

  def initialize(base, path)
    @base = Pathname.new(base)
    @path = path
  end

  def path(complete = true)
    return complete ? base.join(@path) : @path
  end

  def load(from = nil)
    path = from ? Pathname.new(from).join(self.path(true)) : self.path
    begin
      return require path
    rescue NameError => e
      return nil
    end
  end
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
    @paths = paths.map {|path| Pathname.new(path.to_s)}
  end

  def loadables
    if @loadables.empty?
      loadables = []
      self.basedir do
        @paths.each do |path|
          base = path.to_s
          Dir.glob(path.join('**/*.rb'))
            .sort
            .map {|file| file.gsub(/^#{Regexp.quote(base)}\//, '')}
            .map {|file| Pathname.new(file)}
            .reject {|file| /^__(.*)__\.rb$/.match(file.basename.to_s)}
            .each {|file| loadables.push(Loadable.new(base, file))}
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

exit Grouik::Cli.run if __FILE__ == $0
