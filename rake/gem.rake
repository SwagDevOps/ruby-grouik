# frozen_string_literal: true

require 'cliver'
require 'securerandom'

desc 'Build all the packages'
task :gem => ['gem:gemspec', 'gem:package']

namespace :gem do
  # desc Rake::Task[:gem].comment
  task :package => ['gem:gemspec'] + Dir.glob('src/**/*.rb') do
    require 'rubygems/package_task'

    # internal namespace name
    ns = '_%s' % SecureRandom.hex(4)
    namespace ns do
      task = Gem::PackageTask.new(Project.spec)
      task.define
      # Task management
      Rake::Task['%s:package' % ns].invoke
      Rake::Task['clobber'].reenable
    end
  end

  desc 'Update gemspec'
  task :gemspec => "#{Project.name}.gemspec"

  desc 'Install gem'
  task :install => ['gem:package'] do
    spec = Project.spec

    sh(*[Cliver.detect(:sudo),
         Cliver.detect!(:gem),
         :install,
         "pkg/#{spec.name}-#{spec.version}.gem"].compact.map(&:to_s))
  end
end
