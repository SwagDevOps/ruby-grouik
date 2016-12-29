require 'pathname'

class Grouik::Loadable
  attr_reader :base
  attr_reader :path

  def initialize(base, path)
    @base = Pathname.new(base)
    @path = path
  end

  def path(complete = true)
    return complete ? base.join(@path) : @path
  end

  def load(from = nil)
    path = from ? Pathname.new(from).join(self.path(true)) : self.path
    begin
      return require path
    rescue NameError => e
      return nil
    end
  end
end
