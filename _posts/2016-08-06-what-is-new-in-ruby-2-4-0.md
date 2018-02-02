---
title: "What's new in Ruby 2.4.0?"
date: 2016-08-06 16:18:00
categories:
- Ruby
---
Ruby 2.4.0 is coming and, since an official release is still on the oven, we can play around with new improvements in the [preview1][preview1], released a couple of months ago.

If you don't know how to install this preview, *RVM* allows you to install it easily (if you're not using RVM/Rbenv/etc, well, you should):

{% highlight bash %}
# Install Preview1
$ rvm install 2.4.0-preview1

# Switch Ruby
$ rvm use 2.4.0-preview1
{% endhighlight %}

So, once the preview1 is installed and in use, let's play:

_______

## Integer to rule them all

In Ruby 2.3.0, integer numbers were represented by 3 different classes: _Integer, Fixnum and Bignum_.

In 2.4.0, they remain available, but *the only concrete class is Integer*.
_Fixnum and Bignum_ are now just aliases to _Integer_. Check it out:

{% highlight ruby %}
2.4.0-preview1 :014 > Bignum
 => Integer
2.4.0-preview1 :015 > Fixnum
 => Integer
2.4.0-preview1 :016 > 123.class
 => Integer
2.4.0-preview1 :017 > 100_000_000_000_000_000_000.class
 => Integer
2.4.0-preview1 :018 > 123.is_a? Integer
 => true
2.4.0-preview1 :019 > 123.is_a? Fixnum
 => true
{% endhighlight %}

_______

## Case conversion now works with Unicode

Have you already got trolled by Ruby 2.3.0 when asked to upcase the word "época" (_epoch_ in portuguese) or any other string with non-ascii character and got as result something like _éPOCA_?

Well, this is not going to happen anymore on 2.4.0.

Now, case conversion methods (like _upcase_, _downcase_, _capitalize_, etc) works with Unicode strings as well:

{% highlight ruby %}
2.4.0-preview1 :020 > "época".upcase
 => "ÉPOCA"
2.4.0-preview1 :021 > "época".downcase
 => "época"
2.4.0-preview1 :022 > "época".capitalize
 => "Época"
{% endhighlight %}

_______

## _to_time_ now preserves timezone

In older Ruby versions, when asking for _to_time_ in _Time_ and _DateTime_ objects, the timezone were lost.
Ruby 2.4.0 incorporates a bugfix fixing this behavior. Check it out:

{% highlight ruby %}
2.4.0-preview1 :041 > offset = 3.0 / 24 # Timezone: +03:00
 => 0.125
2.4.0-preview1 :042 > dt = DateTime.new.new_offset(offset)
 => #<DateTime: -4712-01-01T03:00:00+03:00 ((0j,0s,0n),+10800s,2299161j)>
2.4.0-preview1 :043 > dt.zone
 => "+03:00"
2.4.0-preview1 :044 > dt.to_time
 => -4712-01-01 03:00:00 +0300
{% endhighlight %}

_______

## Performance improvements

Some performance improvements will be released as well, such like:

* *Array#max* and *Array#min* no longer creates a temporary array under certain circumstances, which improves the response time and reduce the amount of memory used by your code.
* Added *Regex#match?*, which just check if a given string matches the pattern, without creating a back reference object.
* *Thread#report_on_exception* and *Thread.report_on_exception* added. When set to *true*, a report is generated when a thread dies. Today, you can only notice this behavior if another thread explicitly joins it.

[preview1]: https://www.ruby-lang.org/en/news/2016/06/20/ruby-2-4-0-preview1-released/
