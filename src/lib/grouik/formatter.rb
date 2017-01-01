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
