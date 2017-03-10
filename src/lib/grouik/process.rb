# frozen_string_literal: true

require 'pathname'

require 'grouik/concerns'

# Intended to wrap ``Grouik::Loader``
#
# Easify reusability through ``Grouik::Cli``
# or as standalone (for example in a Rake task)
#
# Sample of use:
#
# ~~~~
# task 'src/ceres.rb' do
#  require 'grouik'
#
#  Grouik.process do |process|
#    process.verbose  = false
#    process.paths    = ['lib']
#    process.basedir  = 'src'
#    process.output   = 'src/ceres.rb'
#    process.template = 'src/ceres.tpl'
#  end.on_failure { exit Errno::ECANCELED::Errno }
# end
# ~~~~
class Grouik::Process
  attr_accessor :template
  attr_accessor :bootstrap
  attr_accessor :verbose
  attr_reader   :output

  include Grouik::Concerns::Helpable

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
    !!@verbose
  end

  # @param [Pathname|String] output
  # @return [Object]
  def output=(output)
    @output = output.is_a?(String) ? Pathname.new(output) : output
  end

  # @return [self]
  # @todo Do not suppress exceptions
  def process
    @output.write('') if @output.respond_to?(:file?) and !@output.exist?
    if bootstrap
      begin
        require bootstrap if bootstrap
      rescue NameError
      rescue LoadError
      end
    end

    output = @loader.format(template: @template)
    display_errors
    # avoid to break previouly written file in case of failure
    @output.write(output) if success?

    self
  end

  # @param [Hash] options
  def format(options = {})
    @loader.format(options)
  end

  # Errors encountered during process
  #
  # @return [Hash]
  def errors
    loader.errors
  end

  # Denote errors encountered
  #
  # @return [Boolean]
  def errors?
    errors.empty? ? false : true
  end

  # Display encountered errors
  #
  # @return [self]
  def display_errors
    helpers.get(:process).display_errors(self)

    self
  end

  # Display status
  #
  # @return [self]
  def display_status
    helpers.get(:process).display_status(self)

    self
  end

  # Denote process is a success
  #
  # @return [Boolean]
  def success?
    loader.loaded? and !errors?
  end

  # Denote process is a failure
  #
  # @return [Boolean]
  def failure?
    !success?
  end

  # Block executed on failure
  #
  # @yield [self] Block executed when errors have been encountered
  # @return [self]
  def on_failure
    yield(self) if failure?

    self
  end

  # Block executed on success
  #
  # @yield [self] Block executed when process is a success
  # @return [self]
  def on_success
    yield(self) if success?

    self
  end

  # Provides access to public accessors
  def method_missing(method, *args, &block)
    if respond_to_missing?(method)
      @loader.public_send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    result = loader_accessors.include?(method.to_sym)
    unless result
      return super if include_private
    end

    result
  end

  # Get loader
  #
  # @return [Grouik::Loader]
  def loader
    @loader.clone.freeze
  end

  protected

  # Get loader public attributes
  #
  # @return [Array]
  def loader_attributes
    loader.public_methods
          .grep(/^\w+=$/)
          .map { |m| m.to_s.gsub(/=$/, '').to_sym }
  end

  # Get loader public accessors
  #
  # @return [Array]
  def loader_accessors
    loader_attributes + loader_attributes.map { |m| ('%s=' % m).to_sym }
  end
end
