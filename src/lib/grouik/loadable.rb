require 'pathname'

# Describe a loable item (Ruby file)
class Grouik::Loadable
  attr_reader :base
  attr_reader :path
  attr_reader :basedir

  # @param [String] base
  # @param [String] path
  # @param [String] basedir
  def initialize(base, path, basedir = '.')
    @base = Pathname.new(base)
    @path = path
    @basedir = Pathname.new(basedir).realpath
  end

  # @param [Boolean] format format as loadable from ``$LOAD_PATH``
  # @return [String]
  def path(format = false)
    path = @path.to_s

    {
      true  => path,
      false => basedir.join(base, path).to_s
    }[(format and loadable?)].gsub(/\.rb$/, '')
  end

  # @return [String]
  def to_s
    path(true)
  end

  # @return [Boolean]
  def load(from = nil)
    path = from ? Pathname.new(from).join(self.path) : self.path

    return require path
  end

  def loadable?
    self.class.paths.include?(basedir.join(base).to_s)
  end

  class << self
    # @return [Array<String>]
    def paths
      $LOAD_PATH.map(&:to_s)
    end
  end
end
