# frozen_string_literal: true

require 'optparse'
require 'ostruct'
require 'pathname'
require 'yaml'

require 'grouik' unless defined?(Grouik)
require 'grouik/concerns'

# Grouik command line interface
#
# Provides a ready to use program, based on ``Grouik`` library
class Grouik::Cli
  attr_reader :argv
  attr_reader :options
  attr_reader :arguments

  include Grouik::Concerns::Helpable

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
    parser = helpers.get(:cli).make_parser(@options)
    parser.banner = 'Usage: %s [OPTION]... [FILE]...' % program_name

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
        config = helpers.get(:cli).read_config(filepath)

        processables << OpenStruct.new(
          path: Pathname.new(filepath).dirname,
          file: Pathname.new(filepath),
          options: config,
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
    parse!

    if options[:version]
      STDOUT.puts helpers.get(:cli).version_chapter
      return 0
    end

    processables.each do |processable|
      Dir.chdir(processable.path) do
        process(processable.options)
      end
    end
    0
  end

  protected

  # Initiate and run a new ``Process`` from options
  #
  # @param [Hash] options
  # @return [Grouik::Process]
  def process(options)
    options = helpers.get(:cli).prepare_options(options)

    process = Grouik.process do |process|
      process.basedir   = options.fetch(:basedir)
      process.paths     = options.fetch(:paths)
      process.ignores   = options[:ignores]
      process.output    = options.fetch(:output)
      process.template  = options[:template]
      process.bootstrap = options[:require]
    end

    process.on_success do |process|
      process.display_status if options[:stats]
    end.on_failure do |process|
      process.display_status if options[:stats]
      exit Errno::ECANCELED::Errno
    end

    process
  end
end
