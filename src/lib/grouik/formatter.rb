# frozen_string_literal: true

require 'pathname'
require 'tenjin'

# Formatter used to render loadables
class Grouik::Formatter
  attr_reader :options
  attr_reader :loadables
  attr_reader :template

  def initialize(loadables, options = {})
    @loadables = loadables
    @options   = options
    @formatted = nil
    @engine    = Tenjin::Engine.new(cache: false)
    @template  = options[:template]
  end

  # @return [Pathname|nil]
  def template
    @template ? Pathname.new(template).realpath : nil
  end

  def to_s
    formatted
  end

  def format
    @formatted = @formatted.nil? ? output : @formatted

    return self
  end

  def formatted
    format
    @formatted.clone
  end

  class << self
    def format(loadables, options = {})
      self.new(loadables, options).format
    end
  end

  protected

  def output
    items = loadables.to_a.map { |i| "require '#{i}'" }

    return items.join("\n") + "\n" unless template

    context = {
      requirement: lambda do |indent = nil|
        items.map { |i| '%s%s' % [indent, i] }.join("\n")
      end
    }

    @engine.render(template.to_s, context)
  end
end
