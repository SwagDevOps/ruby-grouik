# frozen_string_literal: true

desc 'Build all the packages'
task :gem => ['gem:gemspec', 'gem:package']

namespace :gem do
  # desc Rake::Task[:gem].comment
  task :package => ['gem:gemspec'] + Dir.glob('src/**/*.rb') do
    require 'rubygems/package_task'
    require 'securerandom'

    # internal namespace name
    ns = '_%s' % SecureRandom.hex(4)
    namespace ns do
      task = Gem::PackageTask.new(Project.spec)
      task.define
      # Task management
      begin
        Rake::Task['%s:package' % ns].invoke
      rescue Gem::InvalidSpecificationException => e
        STDERR.puts(e)
        exit 1
      end
      Rake::Task['clobber'].reenable
    end
  end

  desc 'Update gemspec'
  task :gemspec => "#{Project.name}.gemspec"

  desc 'Install gem'
  task :install => ['gem:package'] do
    require 'cliver'

    spec = Project.spec

    sh(*[Cliver.detect(:sudo),
         Cliver.detect!(:gem),
         :install,
         "pkg/#{spec.name}-#{spec.version}.gem"].compact.map(&:to_s))
  end
end
