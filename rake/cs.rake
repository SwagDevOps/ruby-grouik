# A Ruby static code analyzer, based on the community Ruby style guide.
#
# @see http://batsov.com/rubocop/
# @see https://github.com/bbatsov/rubocop

namespace :cs do
  require 'rubocop/rake_task'
  # Options
  options = {
    'cs:control' => ['--fail-level', 'E'],
    'cs:correct' => ['--fail-level', 'E', '--auto-correct'],
  }

  desc 'Run static code analyzer'
  task :control, [:path] => ['gem:gemspec'] do |t, args|
    paths = Project.spec.require_paths

    RuboCop::RakeTask.new('%s:rubocop' % t.name) do |task|
      task.options       = options.fetch(t.name)
      task.patterns      = args[:path] ? [args[:path]] : paths
      task.fail_on_error = true
    end

    Rake::Task['%s:rubocop' % t.name].invoke
  end

  desc 'Run static code analyzer, auto-correcting offenses'
  task :control, [:path] => ['gem:gemspec'] do |t, args|
    paths = Project.spec.require_paths

    RuboCop::RakeTask.new('%s:rubocop' % t.name) do |task|
      task.options       = options.fetch(t.name)
      task.patterns      = args[:path] ? [args[:path]] : paths
      task.fail_on_error = true
    end

    Rake::Task['%s:rubocop' % t.name].invoke
  end
end
