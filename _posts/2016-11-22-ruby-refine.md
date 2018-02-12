---
title: "Forget the monkey patch: an introduction to Refinement"
date: 2016-11-22
excerpt: Check here how to do monkey patching without monkey patching
categories:
- Ruby
---
One of the biggest problems in Ruby always was the impossibility to redefine class methods. Popular in many other languages, such practice was made possible in Ruby using a <i>workaround</i>: monkey patching

# What's monkey patching?

Quite probably you've already made one but haven't notice: monkey patching is the ability to extend and/or modify a software in runtime.

This approach become popular in Ruby due the ease to redefine a class and overwriting their methods (the so desired overload).

Let's take an example:

{% highlight ruby %}
class Cow
  def say
    puts 'Moo'.upcase
  end
end

class Dog
  def say
    puts 'Roof'.upcase
  end
end

cow = Cow.new
dog = Dog.new

cow.say # => "MOO"
dog.say # => "ROOF"
{% endhighlight %}

The snippet above define two classes: `Cow` and `Dog`, both implementing the method say, which basically write the animal's sound in uppercase.

However, let's say that, for some reason, you've defined the following snippet somewhere else in your project:

{% highlight ruby %}
class String
  def upcase
    self.reverse
  end
end
{% endhighlight %}

After running your cow/dog say methods, you got a strange behaviour:

{% highlight ruby %}
cow.say # => "ooM"
dog.say # => "fooR"
{% endhighlight %}

What the hell happened?

You, my friend, just got monkey patched!

The snippet above, besides useful in some other part of the system, has messed with the whole Ruby runtime.
It's redefining the String method `upcase`, making it reverse the string instead actually uppercasing it.
The act of redefine this method on runtime is called monkey patching.

It can be useful in some situations but, if used without restrictions, can lead to hard to find bugs on your system.

With that in mind, from Ruby 2.0, we got a better and more secure solution, called **Refinements**.

# Refinement

Refinement, in small words, is the act of monkey patching without messing with the runtime environment.

Using our previous example, you've faced the problem introduced by your last monkey patching, but still want a solution for it.

So, check the module below:

{% highlight ruby %}
module StringRefinement
  refine String do
    def upcase
      self.reverse
    end
  end
end

cow.say # => "MOO"
dog.say # => "ROOF"

using StringRefinement

cow.say # => "ooM"
dog.say # => "fooR"
{% endhighlight %}

The example above makes use of refinement.
Refinement is a module that makes use of the keyword `refine` to (duh) refine a class.
In the example above, the module `StringRefinement` is refining the class `String` and overloading its method `upcase`.

The interesting part is: the refinement isn't used unless it's explicitly invoked. That's why the first two calls of `say` printed the sounds in uppercase, and the last two printed it reversed, since the refinement was invoked right before them.

This is specially useful if you need to refine a method only in a specific context.

For example: if you want to turn your `Cow` class in a `CrazyCow`, you can just include the refinement in the new class:

{% highlight ruby %}
class CrazyCow
  using StringRefinement

  def say
    puts 'Moo'.upcase
  end
end

crazycow = CrazyCow.new

crazycow.say # => "ooM"
cow.say # => "MOO"
dog.say # => "ROOF"
{% endhighlight %}

The refinement was just used in the `CrazyCow` class context, keeping the other classes and, specially, the Ruby runtime, intact.s
