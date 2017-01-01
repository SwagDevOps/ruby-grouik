# frozen_string_literal: true

require 'cliver'

namespace :gem do
  desc 'Build all the packages'
  task :package => ['gem:gemspec'] do
    require 'rubygems/package_task'

    namespace '_gem' do
      task = Gem::PackageTask.new(Project.spec)
      task.define
      # Task management
      Rake::Task['_gem:package'].invoke
      Rake::Task['clobber'].reenable
    end
  end

  desc 'Update gemspec'
  task :gemspec => "#{Project.name}.gemspec"

  desc 'Install gem'
  task :install => ['gem:package'] do
    gem = Project.spec
    sh('sudo', 'gem', 'install', "pkg/#{gem.name}-#{gem.version}.gem")
  end if Cliver.detect('sudo')
end
