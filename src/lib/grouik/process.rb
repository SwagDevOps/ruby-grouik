# frozen_string_literal: true

require 'pathname'

# Intended to wrap ``Grouik::Loader``
#
# Easify reusability through ``Grouik::Cli``
# or as standalone (for example in a Rake task)
class Grouik::Process
  attr_accessor :template
  attr_accessor :bootstrap
  attr_accessor :verbose

  def initialize
    @output    = nil
    @template  = nil
    @bootstrap = nil
    @verbose   = false

    @loader = Grouik::Loader.new
    yield self if block_given?
    @loader.register
  end

  def verbose?
    !!(@verbose)
  end

  # @return [Pathname]
  def output=(output)
    @output = output.is_a?(String) ? Pathname.new(output) : output
  end

  def process
    @output.write('') if @output.respond_to?(:file?)
    if bootstrap
      begin
        require bootstrap if bootstrap
      rescue NameError
      rescue LoadError
      end
    end

    output = loader.format(template: @template)
    display_errors
    @output.write(output)
    display_status if verbose?

    self
  end

  def format(options={})
    loader.format(options)
  end

  # @return [Hash]
  def errors
    loader.errors
  end

  def has_errors?
    !errors.empty?
  end

  def display_errors
    errors.each do |_index, struct|
      STDERR.puts '%s[%s]: %s' % [
                    struct.source,
                    struct.line,
                    struct.message,
                  ]
    end
    self
  end

  # @return [self]
  def display_status
    message  = '%s: %s files; %s iterations; %s errors (%.4f) [%s]'
    statuses = {true  => :success, false => :failure}

    outfile  = @output.to_s
    $:.each do |path|
      reg = /^#{Regexp.quote(path.to_s)}\//
      if reg.match(outfile)
        outfile.gsub!(reg, '').gsub!(/\.rb$/, '')
        break
      end
    end

    Grouik.message do |m|
      m.stream  = STDERR
      m.type    = 'status_%s' % statuses.fetch(loader.loaded?)
      m.content = (message % \
                   [
                     statuses.fetch(loader.loaded?),
                     loader.loadables.size,
                     loader.attempts,
                     errors.size,
                     loader.stats ? loader.stats.real : 0,
                     outfile
                   ]).capitalize
    end
    self
  end

  def success?
    loader.loaded?
  end

  def on_errors(&block)
    block.call(self) if has_errors?

    self
  end

  # Provides access to public accessors
  def method_missing(method, *args, &block)
    unless respond_to_missing?(method)
      message = 'undefined method `%s\' for %s' % [method, inspect]
      raise NoMethodError.new(message)
    end

    @loader.public_send(method, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    loader_accessors.include?(method.to_sym)
  end

  protected

  # @return [Grouik::Loader]
  def loader
    @loader
  end

  # @return [Array]
  def loader_attributes
    loader.public_methods
      .grep(/^\w+=$/)
      .map {|m| m.to_s.gsub(/=$/, '').to_sym }
  end

  # @return [Array]
  def loader_accessors
    loader_attributes + loader_attributes.map { |m| ('%s=' % m).to_sym }
  end
end
