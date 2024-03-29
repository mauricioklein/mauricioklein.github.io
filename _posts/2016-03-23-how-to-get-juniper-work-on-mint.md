---
title: "How to get Juniper working on Mint?"
date: 2016-03-23
excerpt: After a long time banging my head against Juniper, finally it's working on Mint...
categories:
  - Linux
redirect_from:
  - /linux/2016/03/23/how-to-get-juniper-work-on-mint/
---
I'm currently working in a project were the client imposes the use of _VPN_ (using _Juniper_) to access its intranet.

Almost all the necessary setup is automated (some problems still occurs, but we get rid of them easily), but all the steps are described assuming an Ubuntu distro...
So, to get things working on _Linux Mint_, it was necessary some manual work and witchcraft...

However, a special problem was driving me crazy.

Every time, after connecting to _VPN_, the _Network Connect_ started correctly, stayed up for 2 seconds and, then... crash unexpectedly!

I've checked many factors that could lead to such strange behaviour, from browser compatibility to Java version running on browser, without success.

# The Solution

Digging into the deepness of web, I've found the problem.

_Network Connect_ relies on *Xterm* to dispatch a new connection.
However, on _Linux Mint_, _Xterm_ isn't installed by default.

First I thought:

> It can't be that easy...

But, after running...

{% highlight sh %}
$ apt-get install xterm
{% endhighlight %}

... the problem was gone :)
