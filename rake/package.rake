require 'rubygems/package_task'

desc 'Build all the packages'
task :package => "#{Project.name}.gemspec" do
  namespace '_gem' do
    task = Gem::PackageTask.new(Project.spec)
    task.define
    # Task management
    Rake::Task['_gem:package'].invoke
    Rake::Task['clobber'].reenable
  end
end
