require 'pathname'

class Grouik::Loadable
  attr_reader :base
  attr_reader :path
  attr_reader :basedir

  def initialize(base, path, basedir = '.')
    @base = Pathname.new(base)
    @path = path
    @basedir = Pathname.new(basedir).realpath
  end

  def path(options={})
    options[:absolute] = options[:absolute].nil? ? true : options[:absolute]
    options[:stripped] = options[:stripped].nil? ? true : options[:stripped]
    options[:loadable] = options[:loadable].nil? ? false : options[:loadable]

    path = @path.clone
    path = options[:absolute] ? basedir.join(base, path) : path
    path = options[:stripped] ? Pathname.new(path.to_s.gsub(/\.rb$/, '')) : path

    # pp loadable?
    if options[:loadable] and loadable?
      return @path.to_s.gsub(/\.rb$/, '')
    end

    return path
  end

  def load(from = nil)
    path = from ? Pathname.new(from).join(self.path) : self.path
    begin
      return require path
    rescue NameError => e
      return nil
    end
  end

  def loadable?
    self.class.paths.include?(basedir.join(base).to_s)
  end

  class << self
    def paths
      $:.map { |path| path.to_s }
    end
  end
end
