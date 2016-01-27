---
layout: post
title:  How to delete files with special characters?
date: 2016-01-26 23:21:00
categories: Life
comments: true
---
After more than 8 years using Linux day-by-day, I always face some questions and problems that are completely new for me (I think this is the reason why I love Linux :P).

So, I was beginning a new _Ruby on Rails_ project today and, since I was only interest in a RESTFul API, I decided to use the new **Rails-API**, which was integrated with the newest version of _Rails_ gem.

To create a Rest API, the following command do the trick:

```Ruby
rails new my_awesome_app --api
```

However, after running the command above, I realized that the Rails gem version installed on my host wasn't new enough to recognize the __--api__ option.

So, the result was a new ordinary Rails project saved in a directory names __--api__.

# The Problem

**how to delete this little bastard?**

Running...

```sh
$ rm -rf --api
$ rm -rf '--api'
$ ls -1 | grep 'api' | xargs rm -rf # This one is the real face of desperation :P
```

... results in the same error: __--api option is not recognized__.

# The solution

After some research, I found a feature, that's enabled in many other Linux commands, not only __rm__, that was completely new for me.

Putting a __--__ in any part of the command says to the interpreter __"Stop parsing option from now on"__

So, if I run...

```sh
$ rm -- --foo --bar
```

... it won't recognize __--foo__ and __--bar__ as flags to __rm__ command, but instead will treat them as regular parameters to command.

So, to solve our original problem, the command below is all we need:

```sh
$ rm -rf -- --api
```
