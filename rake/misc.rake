desc 'Reformat .gitignore file'
task '.gitignore' do
  require 'pathname'

  file = Pathname.new('.gitignore')

  if file.exist?
    content = file.read.lines
                .sort_by { |m| m.downcase }
                .map { |m| m.rstrip }
                .reject(&:empty?)
                .reject { |m| m[0] == '#' }
                .join("\n")

    file.write(content)
  end
end
