# Adopt a Pig (Programmable Inclusions Generator)

Grouik is a french onomatopoeia of a pig's shriek.

Tired to require your own library file transversally from one file to
another? If so, you should give a try to ``Grouik``. It will allow you
to completely automate this task.

``Grouik`` eliminates the drudgery of handcrafting `require`
statements for each Ruby source code file in your project.

A CLI (Command Line Interface) is provided.
The CLI should be seen as a shortcut to discover the power of ``Grouik``.
In the other hand, ``grouik`` can easily be used through
[``ruby/rake``](https://github.com/ruby/rake),
[``erikhuda/thor``](https://github.com/erikhuda/thor)
or any other command-line interface.

## Command Line Interface

~~~~
Usage: grouik [OPTION]... [FILE]...
        --basedir=BASEDIR            Basedir [.]
    -o, --output=OUTPUT              Output [/dev/stdout]
    -r, --require=REQUIRE            Required file on startup
        --ignores x,y,z              Ignores
        --paths x,y,z                Paths
        --[no-]stats                 Display some stats
~~~~

No options are required, no arguments are required. Easy (and safe) to use.

CLI can also use [YAML](https://fr.wikipedia.org/wiki/YAML)
configuration files, as arguments. They use the following structure:

~~~~
basedir: src
paths:   [lib]
output:  src/awesome.rb
require: src/config/init
ignores: [^useless$, ^pointless$]
template: src/awesome.tpl
~~~~

Note: configurations can be overriden by options given on the command-line.

## Sample of (programmatic) use

``Grouik`` can be programmatically used through
[``Rake``](http://rake.rubyforge.org/) tasks:

```ruby
Grouik.process do |process|
    process.basedir   = 'src'
    process.paths     = ['lib']
    process.ignores   = [/^useless$/, /^pointless$/]
    process.output    = 'lib/awesome.rb'
    process.template  = 'lib/awesome.tpl'
    process.bootstrap = nil
end.on_failure { exit Errno::ECANCELED::Errno }
```

``Grouik::Process`` provides methods to be executed on ``success``/``failure``.

## Templating

```ruby
$:.unshift "#{__dir__}/lib"

#{@requirement.call}
```

Grouik uses [``Tenjin``](http://www.kuwata-lab.com/tenjin/) as template engine.
As a result, the following preprocessing statement:

```ruby
#{@requirement.call}
```

will be rendered in as many statements as necessary,
including each source file listed during the process,
ordered by successful loading order.

## Principles

Grouik will attempt ``(n^2)+1`` times before failing.
Success is defined by a complete (without error) loading of all entries.
On failure, CLI __SHOULD__ exit with a ``125`` (``ECANCELED``) return code.

The output file is overwritten when the process is a success.

## Installation

~~~~
sudo gem install grouik
~~~~

alternatively, install a development version (from github):

~~~~
git clone https://github.com/SwagDevOps/ruby-grouik grouik
cd !$
bundle install --path vendor/bundle
rake gem:install
~~~~

## Alternatives

* [Autoloaded](https://njonsson.github.io/autoloaded/)
