---
layout: post
title:  "What to do when <i>docker-compose run</i> don't bind ports?"
date:   2015-05-28 08:00:00
categories: docker
banner_image: docker.png
comments: false
excerpt: <i>docker-compose run</i> isn't forwarding your ports? Check here how to fix it.
---
Docker is a great tool to create a self-contained environment to run you applications, dealing easily with the problems of package dependencies and other stuffs that bother every programmer.

However, generally, an application depends of another resources, like databases, cache or even other applications.

To solve this problem, docker provides the <i>docker-compose</i> command, which handles all dependencies of a system.

Generally, to lift a whole environment, a simple <i>docker-compose up</i> is enough. However, sometimes, we want to send a specific command to a starting container. For exemple:

{% highlight sh %}
docker-compose run api bash
{% endhighlight %}

The command above will start the environment described in <i>docker-compose.yml</i> running an interactive bash in the container labeled as <i>api</i>.

The problem cames when we do a port forward. By default, docker-compose run do not forward the ports. This isn't a bug, but its default behavior, as described in [official documentation][docker-compose-run-docs].

To evercome this behavior, docker-compose run provides the <b>--service-ports</b> parameter, which enable the port forwarding in docker-compose run.

So, our previous command becomes something like:
{% highlight sh %}
docker-compose run --service-ports api bash
{% endhighlight %}

Now, all ports forward described in docker-compose.yml will be processed correctly.

(PS: Thanks to [Tiago Oliveira][tiago-page] for helping me to figure it out :) )

[tiago-page]: http://tiagodeoliveira.github.io/
[docker-compose-run-docs]:  https://docs.docker.com/compose/cli/#run
