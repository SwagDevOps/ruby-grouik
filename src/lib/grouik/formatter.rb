class Grouik::Formatter
  attr_reader :options
  attr_reader :loadables

  def initialize(loadables, options = {})
    @loadables = loadables
    @options   = options
    @formatted = nil
  end

  def to_s
    formatted
  end

  def format
    @formatted = @formatted.nil? ? make_output : @formatted
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

  def make_output
    lines = []
    loadables
      .map { |i| 'require \'%s\',' % i.path(loadable: true) }
      .each { |line| lines.push(line) }.join("\n") + "\n"
  end
end
