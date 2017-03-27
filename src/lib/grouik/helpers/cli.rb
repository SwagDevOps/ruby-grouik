# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

require 'optparse'

# Cli helper, see ``Grouik::Cli``
class Grouik::Helpers::Cli
  class << self
    # Provide an ``OptionParser``
    #
    # @param [Hash] options
    # @return [OptionParser]
    def make_parser(options = {})
      parser = OptionParser.new

      {
        basedir: ['--basedir=BASEDIR', 'Basedir [%s]' % options[:basedir]],
        output: ['-o=OUTPUT', '--output=OUTPUT', 'Output [/dev/stdout]'],
        require: ['-r=REQUIRE', '--require=REQUIRE',
                  'Required file on startup'],
        ignores: ['--ignores x,y,z', Array, 'Ignores'],
        paths: ['--paths x,y,z', Array, 'Paths'],
        stats: ['--[no-]stats', 'Display some stats'],
        version: ['--version', 'Display the version and exit']
      }.each do |k, v|
        parser.on(*v) { |o| options[k] = o }
      end

      parser
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
      config = YAML.safe_load(file.read)

      h = config.each_with_object({}) do |(k, v), n|
        n[k.intern] = v
      end

      h
    end
  end
end
