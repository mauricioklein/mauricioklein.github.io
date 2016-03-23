---
layout: post
title:  How to get Juniper to work on Mint?
date: 2016-03-23 11:22:00
categories: Linux
comments: true
excerpt: After a long time banging my head against Juniper, finally it's working on Mint...
---
I'm currently working in a project were the client imposes the use of _VPN_ (using _Juniper_) to access its intranet.

Almost all the necessary setup is automated (some problems occurs yet, but we get rid of it easily), but its described assuming an Ubuntu distro...
So, to get things working on Mint, it was necessary some manual work and witchcraft...

However, a special problem was driving me crazy.

Every time, after connecting to _VPN_, the _Network Connect_ started correctly, stayed for 2 seconds and, then... crash unexpectedly!

I've checked many possibilities for this strange behavior, since browser compatibility until Java version running on browser.

# The Solution

Digging in the deepness of web, I found the problem.

_Network Connect_ relies on *Xterm* to dispatch a new connection.
However, on _Linux Mint_, _Xterm_ isn't installed by default.

First I thought:

> It can't be that easy...

But, after running...

{% highlight sh %}
$ apt-get install xterm
{% endhighlight %}

... the problem is gone :)
