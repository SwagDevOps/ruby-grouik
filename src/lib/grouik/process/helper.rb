# frozen_string_literal: true

# Helper providing outputs (mostly useful in a CLI/Rake context)
#
# Main methods are ``display_errors`` and ``display_status``
class Grouik::Process::Helper
  # @param [Grouik::Process] process
  def initialize(process)
    @process = process
  end

  # Display loading errors
  #
  # @return [self]
  def display_errors
    process.errors.each do |_index, struct|
      Grouik.message do |m|
        m.stream  = STDERR
        m.type    = 'error'
        m.content = ('%s:%s: %s' % [
                       struct.source,
                       struct.line,
                       struct.message,
                     ])
      end
    end
  end

  # Display (on ``STDERR``) loader related statistics
  #
  # @return [self]
  def display_status
    message  = '%s: %s files; %s iterations; %s errors (%.4f) [%s]'
    loader   = process.loader

    Grouik.message do |m|
      m.stream  = STDERR
      m.type    = 'status_%s' % process_status
      m.content = (message %
                   [
                     process_status.to_s.capitalize,
                     loader.loadables.size,
                     loader.attempts,
                     loader.errors.size,
                     loader.stats ? loader.stats.real : 0,
                     format_filepath(process.output)
                   ])
    end
    self
  end

  # Denote status from process
  #
  # @return [Symbol]
  def process_status
    statuses = {true  => :success, false => :failure}

    statuses.fetch(process.success?)
  end

  protected

  # @return [Grouik::Process]
  def process
    @process
  end

  # Format a filepath with a ``require`` format
  #
  # @param [Pathname|String|Object] filepath
  def format_filepath(filepath)
    filepath = filepath.to_s

    $:.each do |path|
      reg = /^#{Regexp.quote(path.to_s)}\//
      if reg.match(filepath)
        filepath.gsub!(reg, '').gsub!(/\.rb$/, '')
        break
      end
    end

    filepath
  end
end
