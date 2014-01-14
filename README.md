### JRuby Java interface implementation strategies benchmark

Summarized benchmark results of different Java interface implementation strategies using JRuby.

The idea is to see the performance impact of using different strategies to implement the `java.util.Comparator` interface in JRuby. The Ruby `sort!` method and the Java `Collections::sort` method are used over collections of **Ruby Strings**, **Java Strings** and *Comparable* **Objects**.

#### Usage

```
$ rake run
```

#### Tests

- **default Ruby comparator**: Ruby `sort!` method with default comparator.
- **closure Ruby comparator**: Ruby `sort!` method with comparator block.
- **default Java comparator**: Java `Collections::sort` method with default comparator.
- **closure Java comparator**: Java `Collections::sort` method with comparator block using the closure conversion interface implementation of `java.util.Comparator`.
- **mixin Java comparator**: Java `Collections::sort` method with comparator class using the module mixin interface implementation of `java.util.Comparator`.
- **native Java comparator**: Java `Collections::sort` method with comparator native Java class implementation of `java.util.Comparator`.

#### Collections

4M random 4-chars strings are generated and the same base collection is used to create the following collections:

- **Ruby Strings:** Ruby Array of Ruby String
- **Java Strings:** java.util.ArrayList of java.lang.String
- **Objects:** Ruby Array of *Comparable* Ruby objects with a string attribute

#### Results summary

Comparator | Ruby Strings | Java Strings | Objects
--- | --- | --- | ---
default Ruby comparator | **8.15**s<sup>(1)</sup> | N/A | **17.60s**<sup>(3)</sup>
closure Ruby comparator | 18.20s | N/A | 28.78s
default Java comparator | **8.09**s<sup>(1)</sup> | 3.54s | N/A
closure Java comparator | 50.05s | 46.78s | **32.06**s<sup>(2)</sup>
mixin Java comparator | 39.14s | 35.17s | **19.06**s<sup>(2)(3)</sup>
native Java comparator | **8.25s**<sup>(1)(4)</sup> | 3.99s | N/A

#### Observations

1. As expected both Ruby `sort!` and Java `Collections::sort` on Ruby strings collection yield similar performance.
2. Curiously using closure/mixin comparator on *Comparable* Ruby objects is significantly faster than on Ruby strings. Also, using the mixin comparator is faster than using closure comparator.
3. Interesting: Ruby `sort!` using default comparator on *Comparable* objects and Java `Collections::sort` using the mixin comparator on *Comparable* objects has similar performance.
4. Implementing a custom comparator natively in Java is **very fast** on Ruby collections.

#### Conclusions

- Using a module mixin Java comparator on *Comparable* objects is the **most efficient option in Ruby**.
- Implementing a custom comparator natively in Java is the fastest option.
- **Odly**, a closure comparator **is slower** than mixin comparator, see profiling investigation below.
- Both closure and mixin comparators are **significantly slower** on Ruby strings collection than on *Comparable* objects which is probably explained by the **String conversions when crossing the Ruby/Java boundary**.

#### Closure comparator profiling

This is the relevant part of the profiling of the closure Java comparator on Ruby strings:

```
---------------------------------------------------------------------------------------------------------
                      70.23       50.56       19.67                   1/1  Object#java_sort_with_closure_comparator
    99%     71%       70.23       50.56       19.67                     1  Java::JavaUtil::Collections.sort
                      19.67       15.25        4.42     82562064/82562064  #<Class:0x6e36a818>#method_missing
---------------------------------------------------------------------------------------------------------
                      19.67       15.25        4.42     82562064/82562064  Java::JavaUtil::Collections.sort
    28%     21%       19.67       15.25        4.42              82562064  #<Class:0x6e36a818>#method_missing
                       4.42        4.42        0.00     82562064/82562064  String#<=>
---------------------------------------------------------------------------------------------------------
                       4.42        4.42        0.00     82562064/82562064  #<Class:0x6e36a818>#method_missing
     6%      6%        4.42        4.42        0.00              82562064  String#<=>
```

We can see time is lost in `#method_missing`. In fact, looking at the JRuby source code in [core/src/main/java/org/jruby/javasupport/JavaUtil.java](https://github.com/jruby/jruby/blob/1.7.10/core/src/main/java/org/jruby/javasupport/JavaUtil.java#L222) we can see that the closure interface implementation is handled using a `#method_missing` indirection. This is probably something that could be improved.

### Author
**Colin Surprenant**, http://github.com/colinsurprenant/, [@colinsurprenant](http://twitter.com/colinsurprenant/), colin.surprenant@gmail.com, http://colinsurprenant.com/

### License
Apache License, Version 2.0. See the `LICENSE.md` file.
