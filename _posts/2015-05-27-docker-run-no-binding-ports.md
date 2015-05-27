---
layout: post
title:  "What to do when <i>docker-compose run</i> don't bind ports?"
date: 2015-05-27 14:04:00
categories: Docker
banner_image: docker.png
comments: false
excerpt: <i>docker-compose run</i> isn't forwarding ports? Check here to know how to fix it.
---
Docker is a great tool to create a self-contained environment to run your applications, dealing easily with the problems of package dependencies and other stuffs that bother every software developer.

However, generally, an application depends of another resources, like databases, cache or even other applications.

To solve this problem, docker provides the <i>docker-compose</i> command, that handles all system dependencies.

Generally, to lift a whole environment, a simple <i>docker-compose up</i> is enough. However, sometimes, we want to run a specific command to a starting container.

For example:
Let's suppose we have the following <i>docker-compose.yml</i> file

{% gist mauricioklein/e40cfdbbda912f59c311 docker-compose.yml %}

Running...

{% highlight sh %}
docker-compose run api bash
{% endhighlight %}

... will start the environment described in <i>docker-compose.yml</i>, executing an interactive bash in the container labelled as <i>api</i>.

The problem cames when we do a port forward. By default, <i>docker-compose run</i> don't forward its ports. This isn't a bug, but its default behavior, as described in [Docker's official documentation][docker-compose-run-docs].

To evercome this behavior, <i>docker-compose run</i> provides the <b>--service-ports</b> parameter, which enable port forwarding in <i>docker-compose run</i>.

So, our previous command become something like this:
{% highlight sh %}
docker-compose run --service-ports api bash
{% endhighlight %}

Now, all ports forward described in <i>docker-compose.yml</i> will be processed correctly.

(PS: Thanks to [Tiago Oliveira][tiago-page] for helping me to figure it out :) )

[tiago-page]: http://tiagodeoliveira.github.io/
[docker-compose-run-docs]:  https://docs.docker.com/compose/cli/#run
