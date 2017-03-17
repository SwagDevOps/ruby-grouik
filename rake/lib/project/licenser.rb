# frozen_string_literal: true

# Apply license, provided by ``version_info`` on project files
#
# Samples of use:
#
# ~~~~
# Project::Licenser.new do |a|
#    a.patterns = ['src/bin/*', 'src/**/**.rb']
#    a.license  = Project.version_info[:license]
# end.apply
# ~~~~
#
# ~~~~
# applier = Project::Licenser.new
# applier.files += Dir.glob('src/bin/*')
# applier.apply
# ~~~~
class Project::Licenser
  attr_accessor :license
  attr_accessor :files
  attr_reader   :patterns

  def initialize
    @patterns = []
    @files = []

    yield self if block_given?

    @license ||= Project.version_info[:license]

    return self unless Project.spec and @files.empty?

    @files += Project.spec.files.reject { |f| !f.scan(/\.rb$/)[0] }
  end

  # @param [Array<String>]
  def patterns=(patterns)
    @files = []
    patterns.each do |pattern|
      @files += Dir.glob(pattern)
    end

    @patterns = patterns
  end

  # @return [Array<Pathname>]
  def files
    @files.each.map { |file| Pathname.new(file) }.sort
  end

  # Get license, formatted (using comments)
  #
  # @return [String]
  def license
    @license.to_s.gsub(/\n{3}/mi, "\n\n").lines.map do |line|
      line.chomp!

      line = "# #{line}" if line and line[0] != '#'
    end.join("\n")
  end

  # @return [Regexp]
  def license_regexp
    /#{Regexp.quote(license)}/mi
  end

  # Apply license
  #
  # @return [self]
  def apply
    yield self if block_given?

    files.each { |file| apply_license(file, license) }

    self
  end

  protected

  # Get an index, skipping comments
  #
  # @param [Array<String>]
  # @return [Fixnum]
  def index_lines(lines)
    index = 0
    loop do
      break unless lines[index] and lines[index][0] == '#'

      index += 1
    end

    index
  end

  def apply_license(file, license)
    return file if file.read.scan(license_regexp)[0] or license.to_s.empty?

    lines = file.read.lines
    index = index_lines(lines)

    content = lines.clone
    if index > 0
      content = lines[0..index] +
                license.lines   +
                ["\n"]          +
                lines[index..-1]
    end

    puts content.join('')
    # file.write(content.join(''))

    file
  end
end
