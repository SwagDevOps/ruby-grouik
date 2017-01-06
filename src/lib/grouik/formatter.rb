require 'pathname'
require 'tenjin'

class Grouik::Formatter
  attr_reader :options
  attr_reader :loadables
  attr_reader :template

  def initialize(loadables, options = {})
    @loadables = loadables
    @options   = options
    @formatted = nil
    @engine    = Tenjin::Engine.new(cache: false)
    @template  = nil

    if options[:template]
      @template = Pathname.new(options[:template]).realpath
    end
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
    def format(loadables, options={})
      self.new(loadables, options).format
    end
  end

  protected

  def output
    items = loadables.map { |i| 'require \'%s\'' % i.path(loadable: true) }
    return items.join("\n") + "\n" unless template

    context = {
      requirement: -> (indent=nil) do
        items.map { |i| '%s%s' % [indent, i]}.join("\n")
      end
    }

    @engine.render(template.to_s, context)
  end
end
