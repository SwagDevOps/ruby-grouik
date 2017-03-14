# frozen_string_literal: true

class Project::Licenser
  attr_reader :license
  attr_accessor :files

  def initialize(license, files=[])
    @license = license
    self.files = files
  end

  def files
    @files.each.map { |file| Pathname.new(file) }
  end

  def license_regexp
    %r{#{Regexp.quote(license)}}mi
  end

  def apply
    files.each do |file|
      next if file.read.scan(license_regexp)[0]
      lines = file.read.lines
      index = index_lines(lines)

      content = lines.clone
      if index > 0
        content = lines[0..index] + license.lines + ["\n"] + lines[index..-1]
      end

      puts content.join('')
      # file.write(content.join(''))
    end
  end

  protected

  def index_lines(lines)
    index = 0
    loop do
      if lines[index] and lines[index][0] == '#'
        index = index + 1
      else
        break
      end
    end

    index
  end
end
