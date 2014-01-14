require 'java'
require 'jruby/profiler'
require 'benchmark'

java_import "JavaNaturalComparator"
java_import "java.util.Comparator"
java_import "java.util.Collections"
java_import "java.util.ArrayList"

# dummy Comparable object
class O
  include Comparable
  attr_reader :id
  def initialize(id); @id = id; end
  def <=>(other); id <=> other.id; end
  def to_s; id; end
end

# Java interface implemetation using mixin
class RubyNaturalComparator
  include Comparator
  def compare(a, b); a <=> b; end
end

puts("initializing structures")

STRINGS_COUNT = 4000000
CHARS = ('a'..'z').to_a.freeze
STRINGS = (1..STRINGS_COUNT).map{CHARS.shuffle[0, 4].join.freeze}.freeze
JAVA_STRINGS = ArrayList.new(STRINGS.map(&:to_java))
OBJECTS = STRINGS.map{|s| O.new(s)}.freeze

# since Java Collections::sort mutates the passed collection, Ruby's sort! is used
# and sorting is done on a dup'ed collection.

def ruby_sort(collection, &comparator)
  comparator ? collection.sort!(&comparator) : collection.sort!
end

def java_sort_with_closure_comparator(collection, &comparator)
  comparator ? Collections::sort(collection, Comparator.impl(&comparator)) : Collections::sort(collection)
end

def java_sort_with_mixin_comparator(collection, comparator)
  Collections::sort(collection, comparator)
end

benchmarks = [
  {:title => "default Ruby comparator on strings",      :code => lambda{ruby_sort(STRINGS.dup)}},
  {:title => "default Ruby comparator on objects",      :code => lambda{ruby_sort(OBJECTS.dup)}},

  {:title => "closure Ruby comparator on strings",      :code => lambda{ruby_sort(STRINGS.dup){|a, b| a <=> b}}},
  {:title => "closure Ruby comparator on objects",      :code => lambda{ruby_sort(OBJECTS.dup){|a, b| a <=> b}}},

  {:title => "default Java comparator on Ruby strings", :code => lambda{java_sort_with_closure_comparator(STRINGS.dup)}},
  {:title => "default Java comparator on Java strings", :code => lambda{java_sort_with_closure_comparator(JAVA_STRINGS.clone)}},

  {:title => "closure Java comparator on Ruby strings", :code => lambda{java_sort_with_closure_comparator(STRINGS.dup){|method, a, b| a <=> b}}},
  {:title => "closure Java comparator on Java strings", :code => lambda{java_sort_with_closure_comparator(JAVA_STRINGS.clone){|method, a, b| a <=> b}}},
  {:title => "closure Java comparator on objects",      :code => lambda{java_sort_with_closure_comparator(OBJECTS.dup){|method, a, b| a <=> b}}},

  {:title => "mixin Java comparator on Ruby strings",   :code => lambda{java_sort_with_mixin_comparator(STRINGS.dup, RubyNaturalComparator.new)}},
  {:title => "mixin Java comparator on Java strings",   :code => lambda{java_sort_with_mixin_comparator(JAVA_STRINGS.clone, RubyNaturalComparator.new)}},
  {:title => "mixin Java comparator on objects",        :code => lambda{java_sort_with_mixin_comparator(OBJECTS.dup, RubyNaturalComparator.new)}},

  {:title => "native Java comparator on Ruby strings",  :code => lambda{java_sort_with_mixin_comparator(STRINGS.dup, JavaNaturalComparator.new)}},
  {:title => "native Java comparator on Java strings",  :code => lambda{java_sort_with_mixin_comparator(JAVA_STRINGS.clone, JavaNaturalComparator.new)}},
]

if ARGV[0] == "benchmark"
  puts("benchmarking")
  benchmarks.each do |b|
    puts
    Benchmark.bmbm{|x| x.report(b[:title], &b[:code])}
  end
elsif ARGV[0] == "profile"
  # do not forget to use --profile.api to enable profiling
  puts("profiling")
  benchmarks.each do |b|
    puts("\n#{b[:title]}\n\n")
    profile_data = JRuby::Profiler.profile{b[:code].call}
    profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
    profile_printer.printProfile(STDOUT)
  end
end