require 'jruby/jrubyc'

begin
  require 'ant'
rescue
  puts("error: unable to load Ant, make sure Ant is installed, in your PATH and $ANT_HOME is defined properly")
  puts("\nerror details:\n#{$!}")
  exit(1)
end

desc "compile Java class"
task :build  do |t, args|
  ant.javac(
    'srcdir' => "./",
    'destdir' => "./",
    'debug' => "yes",
    'includeantruntime' => "no",
    'verbose' => false,
    'listfiles' => true
  ) do
  end
end

JRUBY_PARAMS = "--server -J-Xmx6G -J-Xms6G -J-Djruby.compile.mode=FORCE -J-Djruby.jit.threshold=0 -Xcompile.invokedynamic=true"

desc "run benchmark and profiling"
task :run => :build do
  system("ruby #{JRUBY_PARAMS} interface_strategies.rb benchmark")
  system("ruby #{JRUBY_PARAMS} --profile.api interface_strategies.rb profile")
end

task :default => :run
