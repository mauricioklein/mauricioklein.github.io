---
layout: post
title:  How to delete files with special characters on Linux?
date: 2016-01-26 23:21:00
categories: Life
comments: true
excerpt: After more than 8 years using Linux, sometimes I still got stuck at "unusual situations"...
---
After more than 8 years using Linux day-by-day, sometimes I face some questions and problems that are completely new for me (I think this is the reason why I love Linux :P).

So, I was beginning a new _Ruby on Rails_ project today and, since I was only interest in a _RESTFul API_, I decided to use the new _Rails-API_, which was integrated with the newest version of _Rails_ gem.

To create a Rest API, the following command does the trick:

{% highlight sh %}
rails new my_awesome_app --api
{% endhighlight %}

However, after running the command above, I realized that the Rails gem version installed on my host wasn't new enough to recognize the _- -api_ option.

So, the result was a new ordinary Rails project saved in a directory named _- -api_.

# The Problem

**How to delete this little bastard?**

Running...

{% highlight sh %}
$ rm -rf --api
$ rm -rf '--api'
$ ls -1 | grep 'api' | xargs rm -rf # This one is the real face of desperation :P
{% endhighlight %}

... results in the same error: _- -api option is not recognized_.

# The solution

After some research, I found a feature, that's available in many other Linux commands, not only _rm_, but was completely new for me.

Putting a _- -_ in any part of the command says to the interpreter _"Stop parsing option from now on"_

So, if I run...

{% highlight sh %}
$ rm -- --foo --bar
{% endhighlight %}

... it won't recognize _- -foo_ and _- -bar_ as flags to _rm_ command, but instead will treat them as regular parameters to command.

So, to solve our original problem, the command below is all we need:

{% highlight sh %}
$ rm -rf -- --api
{% endhighlight %}
