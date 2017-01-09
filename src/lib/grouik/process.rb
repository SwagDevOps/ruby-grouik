# frozen_string_literal: true

# Intended to wrap Grouik::Loader and easify reusability through Grouik::Cli
# or as standalone (for example in a Rake task)
class Grouik::Process
  def initialize(paths)
    yield self if block_given?
  end

  def format(options={})
    loader.format(options)
  end

  def errors
    loader.errors
  end

  def display_errors
    errors.each do |file, error|
      STDERR.puts('%s: %s' % [file, error.message])
    end
    self
  end

  def display_status
    message  = '%s: %s files; %s iterations; %s errors (%.4f)'
    statuses = {true  => 'success', false => 'failure',}

    STDERR.puts((message % \
                [
                  statuses.fetch(loader.loaded?),
                  loader.loadables.size,
                  loader.attempts,
                  errors.size,
                  loader.stats ? loader.stats.real : 0
                ]).capitalize)
  end

  def success?
    loader.loaded?
  end

  # Provides access to public accessors
  def method_missing(method, *args, &block)
    unless loader_accessors.include?(method.to_sym)
      message = 'undefined method `%s\' for %s' % [method, inspect]
      raise NoMethodError.new(message)
    end

    @loader.public_send(method, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    self.respond_to?(method, include_private) ? true : super
  end

  protected

  def loader
    @loader
  end

  def loader_attributes
    loader.public_methods
      .grep(/^\w+=$/)
      .map {|m| m.to_s.gsub(/=$/, '').to_sym }
  end

  def loader_accessors
    loader_attributes + loader_attributes.map { |m| ('%s=' % m).to_sym }
  end
end
