---
layout: post
title:  "How Docker changed the way we do tests?"
date: 2015-07-26 12:12:00
categories: Docker Life
comments: true
excerpt: How Docker changed the way we do tests?
---
I'm currently working at [Zenvia Mobile Results][zenvia], brazillian leader in corporate SMS.

Our team is responsable to evolve, fix and maintain many application, most of them with a huge load and many transactions per second.

To keep everything running well, we do a lot (I mean, A LOT) of tests in our platform. Well, that's useless to say, since testing software nowadays isn't an option, but mandatory.

However, even after many tests, we still have bugs happening in production, sometimes things our tests should cover, but they don't.

The question is: why?

Why do we still have bugs happening in production after such an effort in testing our applications? The problem is: we're testing our applications isolated, and assuming that, once each unit is running well, together they will also run harmoniously. This is a huge mistake. It's like saying that a music band will be a huge success just because all band members are great musicians.

So, we figured out that we've a lack in **integration tests**.

Ok, we faced the problem and we know where to enhance. But how?
Integrated tests used to be slow and hard, since each subsystem has its own requirements.

One solution is to simple mock neighbor systems responses and check the system under tests behavior with those responses. That can enhance our tests, but we aren't testing the system under real situations. We all know that a mocked tests is dangerous.

Ok, mocked tests aren't a solution. So we need a way to test our applications _as prod_, something that's not easy.

Here is where Docker shows up.

With Docker, we're able to tests our applications integrated. And integrated I mean: something really close to production behavior.
We can now lift the whole system and prepare them to process a request completely, a real end to end test.

After such improvement in our way to do tests, we're now discovering bugs and misbehaviors we even can't imagine we had until a month ago.
And that's great! Every software, even the most tested one, has bugs. It's our duty to find them and fix.

![][find-you-kill-you]

Now we have a fully integrated test environment, it's time to automate.

This automation can be achieved with **Docker clients**.

To understand it, we first need to understand how Docker works.

Basically, Docker works in a **client-server architecture**. The Docker server is responsable to control all images, containers, etc.
The client simply do requests for server, asking to perform actions, like download a new image, start a container, execute a command in a running container, etc.

So, every _docker_ command you run in your host, you're in fact making a client request to a Docker server. Generally, this server resides in your host, but it can be located somewhere, like a friend's machine or even a server running **Jenkins**, and here's how we will automate our tests.

There are many Docker client implementations for many languages. A quick search on [Github][docker-client-github-search] shows you many possibilities. Zenvia itself has a Docker client for Groovy under development. You can check it out [here][docker-komposer].

So, with a client, you can write your tests in any language and enjoy the power Docker gives you.

For example, you can write your tests in JUnit, starting and stoping your containers programmatically and doing assertions like any regular test. The possibilities are endless.

Once the tests are written, you can easily create triggers on your Jenkins server, asking it to run the tests after each commit in develop, for example.
We now have real tests, running a closer production scenario, integrated in our pipeline.
Of course, those tests are not 100% production like, since we don't have the same load we do in production, but it's a huge improvement compared to our old tests.

To finish, Docker is just one of the available solutions. Many other approaches can be adopted, using containers, virtualization or even lifting your whole system in your host machine. The fact is: there isn't excuses anymore to assume that a well unit tested system is bug free or to test your application in production. Those dark days are gone. A new age of self contained tests has arised, and bug's life is doomed.

You have the weapon on your hand: just aim and pull the trigger.

[zenvia]: http://www.zenvia.com.br/en/
[find-you-kill-you]: {{ site.url }}/assets/images/findyoukillyou.jpg
[docker-client-github-search]: https://github.com/search?utf8=%E2%9C%93&q=docker+client
[docker-komposer]: https://github.com/zenvia-mobile/docker-komposer
