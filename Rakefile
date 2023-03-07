require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rbbt-rest"
    gem.summary = %Q{Rbbt Web and REST interfaces}
    gem.description = %Q{Basic web app controllers and templates}
    gem.email = "miguel.vazquez@cnio.es"
    gem.homepage = "http://github.com/mikisvaz/rbbt-rest"
    gem.authors = ["Miguel Vazquez"]
    gem.files = Dir['lib/**/*.rb', 'share/R/*', 'share/views/**/*', 'config.ru', "Rakefile", 'LICENCE']

    gem.add_dependency('rake')
    gem.add_dependency('sinatra')
    gem.add_dependency('modular-scale')
    #gem.add_dependency('zurb-foundation')
    gem.add_dependency('compass')
    gem.add_dependency('sassc')
    gem.add_dependency('json')
    gem.add_dependency('haml')
    gem.add_dependency('sinatra-authorization')
    gem.add_dependency('sinatra-cross_origin')
    gem.add_dependency('sinatra-contrib')
    #gem.add_dependency('therubyracer')

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.license = "MIT"
  end
  Jeweler::GemcutterTasks.new  
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test
