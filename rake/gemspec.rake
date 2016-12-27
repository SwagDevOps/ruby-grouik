require 'pathname'
require 'gemspec_deps_gen'

desc 'Update gemspec'
task :gemspec => "#{Project.name}.gemspec"

file "#{Project.name}.gemspec" => "src/#{Project.name}.gemspec.erb" do
  chdir 'src' do
    files = ["#{Project.name}.gemspec.erb", "../#{Project.name}.gemspec"]
    gen = GemspecDepsGen.new
    gen.generate_dependencies(*(['s'] + files))

    output = Pathname.new(files[1])
    output.write(output
                .read
                .lines.map {|l| l.rstrip }.join("\n")
                .gsub(/\n*end/, "\nend"))
  end
end
