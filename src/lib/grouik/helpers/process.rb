# frozen_string_literal: true

# Helper providing outputs (mostly useful in a CLI/Rake context)
#
# Main methods are ``display_errors`` and ``display_status``
class Grouik::Helpers::Process
  class << self
    # Display loading errors
    #
    # @param [Grouik::Process] process
    # @return [self]
    def display_errors(process)
      process.errors.each do |_k, struct|
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
    # @param [Grouik::Process] process
    # @return [self]
    def display_status(process)
      message  = '%s: %s files; %s iterations; %s errors (%.4f) [%s]'
      loader   = process.loader

      Grouik.message do |m|
        m.stream  = STDERR
        m.type    = 'status_%s' % status(process)
        m.content = (message %
                     [
                       status(process).to_s.capitalize,
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
    def status(process)
      statuses = { true => :success, false => :failure }

      statuses.fetch(process.success?)
    end

    protected

    # Format a filepath with a ``require`` format
    #
    # @param [Pathname|String|Object] filepath
    def format_filepath(filepath)
      filepath = filepath.to_s

      $LOAD_PATH.each do |path|
        regexp = %r{^#{Regexp.quote(path.to_s)}\/}
        if regexp.match(filepath)
          filepath.gsub!(regexp, '').gsub!(/\.rb$/, '')
          break
        end
      end

      filepath
    end
  end
end