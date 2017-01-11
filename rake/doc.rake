# frozen_string_literal: true

require 'pathname'
require 'yard'
require 'securerandom'

desc "Generate documentation (using YARD)"
task :doc do
  paths = ['src/lib']
  build = 'doc:build:%s' % SecureRandom.hex(4)

  YARD::Rake::YardocTask.new(build) do |t|
    t.files   = paths.map { |f| Pathname.new(f).join('**', '*.rb').to_s }
    t.options = ['-o', 'doc',
                 '--markup-provider=redcarpet',
                 '--markup=markdown']
  end

  Rake::Task[build].invoke
end
