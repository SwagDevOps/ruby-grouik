# frozen_string_literal: true
#
# see: https://gist.github.com/chetan/1827484

desc "Generate documentation (using YARD)"
task :doc do
  [:pathname, :yard, :securerandom].each { |req| require req.to_s }

  # internal task name
  tname = 'doc:build:%s' % SecureRandom.hex(4)
  # documented paths
  paths = ['src/lib']

  YARD::Rake::YardocTask.new(tname) do |t|
    t.files = paths.map do |path|
      Pathname.new(path).join('**', '*.rb').to_s
    end
    t.options = ['-o', 'doc',
                 '--markup-provider=redcarpet',
                 '--markup=markdown']
  end

  Rake::Task[tname].invoke
end
