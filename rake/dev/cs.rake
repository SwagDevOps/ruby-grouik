# A Ruby static code analyzer, based on the community Ruby style guide.
#
# @see http://batsov.com/rubocop/
# @see https://github.com/bbatsov/rubocop

namespace 'dev' do
  command = ['bundle', 'exec', 'rubocop', '--fail-level', 'E']
  default = Dir.pwd # Default path

  desc 'Run static code analyzer'
  task :cs, [:path] do |_t, args|
    sh(*(command + [args[:path] || default]))
  end

  namespace :cs do
    desc 'Run static code analyzer, auto-correcting offenses'
    task :fix, [:path] do |_t, args|
      raise ArgumentError, 'missing argument' if args[:path].nil?

      sh(*(command + ['-a', args[:path]]))
    end
  end
end
