# frozen_string_literal: true

require 'optparse'
require 'ostruct'
require 'pathname'
require 'yaml'

require 'grouik' unless defined?(Grouik)

# Grouik command line interface
#
# Provides a ready to use program, based on ``Grouik`` library
class Grouik::Cli
  attr_reader :argv
  attr_reader :options
  attr_reader :arguments

  class << self
    # Program name
    #
    # @return [String]
    def program_name
      Pathname.new($PROGRAM_NAME).basename('.rb').to_s
    end

    # Run
    #
    # @param [Array] argv
    def run(argv = ARGV)
      self.new(argv).run
    end

    # default options
    def defaults
      {
        stats: true,
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

  # @return [String]
  def program_name
    self.class.program_name
  end

  # Constructor
  #
  # @param [Array] argv
  def initialize(argv = ARGV)
    @argv = argv.clone
    @options = self.class.defaults
    # @options = config unless config.empty?
    @arguments = []
  end

  # Provide an ``OptionParser``
  #
  # @return [OptionParser]
  def parser
    options = @options
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: %s [options] [FILE]' % self.program_name
      opts.on('--basedir=BASEDIR', 'Basedir [%s]' % options[:basedir]) \
      { |v| options[:basedir] = v }
      opts.on('-o=OUTPUT', '--output=OUTPUT', 'Output [/dev/stdout]') do |v|
        options[:output] = v
      end
      opts.on('-r=REQUIRE', '--require=REQUIRE', 'Required file on startup') do |v|
        options[:require] = v
      end

      opts.on('--ignores x,y,z', Array, 'Ignores') \
      { |v| options[:ignores] = v }
      opts.on('--paths x,y,z', Array, 'Paths') \
      { |v| options[:paths] = v }
      opts.on('--[no-]stats', 'Display some stats') \
      { |v| options[:stats] = v }
      opts.on('-v', '--[no-]verbose', 'Run verbosely') \
      { |v| options[:verbose] = v }
    end

    parser
  end

  # Parse command line options
  #
  # Abort process (error code SHOULD BE ``22``) on invalid option
  #
  # @return [self]
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

  # Get processable items (based on command arguments), used during execution
  #
  # @return [Array<OpenStruct>]
  def processables
    processables = []
    if arguments.empty?
      processables[0] = OpenStruct.new(
        path: Pathname.new(Dir.pwd),
        options: options,
        'file?' => false
      )
    else
      arguments.each do |filepath|
        processables << OpenStruct.new(
          path: Pathname.new(filepath).dirname,
          file: Pathname.new(filepath),
          options: self.options.merge(config_from_path(filepath)),
          'file?' => true
        )
      end
    end

    processables.map(&:freeze)
  end

  # Execute CLI and return exit code
  #
  # @return [Fixnum]
  def run
    parse!.processables.each do |processable|
      Dir.chdir(processable.path) do
        process(processable.options)
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
      h = YAML.safe_load(file.read).each_with_object({}) { |(k, v), h| h[k.intern] = v; }
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
  def process(options)
    options = prepare_options(options)

    process = Grouik.process do |process|
      process.basedir   = options.fetch(:basedir)
      process.paths     = options.fetch(:paths)
      process.ignores   = options[:ignores]
      process.output    = options.fetch(:output)
      process.template  = options[:template]
      process.bootstrap = options[:require]
      process.verbose   = !!(options[:verbose])
    end

    process.on_success do |process|
      process.display_status if options[:stats]
    end.on_failure do |process|
      process.display_status if options[:stats]
      exit Errno::ECANCELED::Errno
    end

    process
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

      options[k] = options[k].to_a.map { |s| /#{s}/ } if :ignores == k
    end

    options
  end
end
