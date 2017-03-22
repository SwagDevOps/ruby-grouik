# frozen_string_literal: true

require 'optparse'

# Cli helper, see ``Grouik::Cli``
class Grouik::Helpers::Cli
  class << self
    # Provide an ``OptionParser``
    #
    # @param [Hash] options
    # @return [OptionParser]
    def make_parser(options = {})
      OptionParser.new do |opts|
        opts.on('--basedir=BASEDIR', 'Basedir [%s]' % options[:basedir]) \
        { |v| options[:basedir] = v }
        opts.on('-o=OUTPUT', '--output=OUTPUT', 'Output [/dev/stdout]') do |v|
          options[:output] = v
        end
        opts.on('-r=REQUIRE', '--require=REQUIRE', 'Required file on startup') do |v|
          options[:require] = v
        end

        opts.on('--ignores x,y,z', Array, 'Ignores') \
        { |v| options[:ignores] = v }
        opts.on('--paths x,y,z', Array, 'Paths') \
        { |v| options[:paths] = v }
        opts.on('--[no-]stats', 'Display some stats') \
        { |v| options[:stats] = v }
      end
    end

    # Prepare options
    #
    # Process values in order to easify their use
    #
    # @param [Hash] options
    # @return [Hash]
    def prepare_options(options)
      [:require, :output].each do |k|
        next unless options[k]
        begin
          options[k] = Pathname.new(options[k])
        rescue TypeError
          next
        end
        unless options[k].absolute?
          options[k] = Pathname.new(Dir.pwd).join(options[k])
        end
      end

      [:ignores, :paths].each do |k|
        next unless options[k]
        options[k] = [options[k]] if options[k].is_a? String

        options[k] = options[k].to_a.map { |s| /#{s}/ } if :ignores == k
      end

      options
    end

    # Get the license
    #
    # @return [String]
    def license
      Grouik.version_info[:license].to_s.gsub(/\n{3}/mi, "\n\n")
    end

    # Get a displayable version
    #
    # Some inspiration taken from ``wget --version``
    #
    # @return [String]
    def version_chapter
      ['%s %s on %s' % [Grouik.name, Grouik::VERSION, host_os],
       nil,
       license].join("\n")
    end

    # @return [String]
    def host_os
      RbConfig::CONFIG['host_os']
    end

    # Read a config file
    #
    # @param [String] path
    # @return [Hash]
    def read_config(path)
      file = Pathname.new(path.to_s)

      if file.exist? and file.file?
        h = YAML.safe_load(file.read).each_with_object({}) do |(k, v), h|
          h[k.intern] = v
        end
        return h
      end
      {}
    end
  end
end
