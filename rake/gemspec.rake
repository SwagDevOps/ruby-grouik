desc 'Update gemspec'
task :gemspec => "#{Project.name}.gemspec"

file "#{Project.name}.gemspec" => "src/#{Project.name}.gemspec.erb" do
  require 'gemspec_deps_gen'
  require 'pathname'

  chdir 'src' do
    files = ["#{Project.name}.gemspec.erb", "../#{Project.name}.gemspec"]
    GemspecDepsGen.new.generate_dependencies(*(['s'] + files))

    output = Pathname.new(files[1])
    output.write(output.read.lines
                   .map {|l| l.rstrip }.join("\n")
                   .gsub(/[\n]+[\n]end/, "\nend")
                   .gsub(/[\n]{3,}(\s{2,})/, "\n\n\\1"))
  end
end
