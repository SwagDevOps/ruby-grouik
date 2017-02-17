# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'yaml'

require 'grouik' unless defined?(Grouik)

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
        output: STDOUT,
        ignores: [],
        require: nil,
        template: nil,
      }
    end
  end

  def program_name
    self.class.program_name
  end

  def initialize(argv = ARGV)
    @argv = argv.clone
    @options = self.class.defaults
    # @options = config unless config.empty?
    @arguments = []
  end

  def parser
    options = @options
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: %s [options] [FILE]' % self.program_name
      opts.on('--basedir=BASEDIR', 'Basedir [%s]' % options[:basedir]) \
      {|v| options[:basedir] = v}
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
    # @options = prepare_options(@options)
    self
  end

  # Execute CLI and return exit code
  #
  # @return [Fixnum]
  def run
    parse!
    if argv.empty? and arguments.empty?
      STDERR.puts("%s\nCan not run without arguments and options." % parser)
      return Errno::EINVAL::Errno
    end

    return (process_options(options).success? ? 0 : 1) if argv.empty?

    argv.each do |filepath|
      options = self.options.merge(config_from_path(filepath))

      Dir.chdir(Pathname.new(filepath).dirname) do
        unless process_options(options).success?
          return 1
        end
      end
    end
    0
  end

  # Read a config file
  #
  # @param [String] path
  # @return [Hash]
  def config_from_path(path)
    file = Pathname.new(path.to_s)

    if file.exist? and file.file?
      h = YAML.load(file.read).inject({}){|h,(k,v)| h[k.intern] = v; h}
      h.each do |k, v|

      end
      return h
    end
    {}
  end

  protected

  # Initiate and run a new ``Process`` from options
  #
  # @param [Hash] options
  # @return [Grouik::Process]
  def process_options(options)
    options = prepare_options(options)

    Grouik.process do |instance|
      instance.basedir   = options.fetch(:basedir)
      instance.paths     = options.fetch(:paths)
      instance.ignores   = options[:ignores]
      instance.output    = options.fetch(:output)
      instance.template  = options[:template]
      instance.bootstrap = options[:require]
      instance.verbose   = !!(options[:verbose])
    end
  end

  # Prepare options
  #
  # Process values in order to easify their use
  #
  # @param [Hash] options
  # @return [Hash]
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

      if :ignores == k
        options[k] = options[k].to_a.map { |s| /#{s}/ }
      end
    end

    options
  end
end
