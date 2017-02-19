# frozen_string_literal: true

file "#{Project.name}.gemspec" =>
     ["src/#{Project.name}.gemspec.tpl", 'Gemfile'] do
  require 'gemspec_deps_gen'
  require 'pathname'
  require 'tenjin'
  require '%s/src/lib/%s' % [Dir.pwd, Project.name]

  files   = ["src/#{Project.name}.gemspec.tpl", "#{Project.name}.gemspec"]
  spec_id = Pathname.new(files[1])
              .read
              .scan(/Gem::Specification\.new\s+do\s+\|([a-z]+)\|/)
              .fetch(0).fetch(0)

  depsgen = GemspecDepsGen.new
  context = {
    dependencies: depsgen.generate_project_dependencies(spec_id).strip,
    name: Project.name,
  }.merge(Project.version_info)

  output  = Tenjin::Engine
              .new(cache: false)
              .render(Pathname.new(Dir.pwd).join(files[0]).to_s, context)

  Pathname.new(files[1]).write(output)
end
