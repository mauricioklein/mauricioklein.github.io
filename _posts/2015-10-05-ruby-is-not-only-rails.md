---
title: "Ruby isn't only Rails"
date: 2015-10-05
excerpt: When you hear 'Ruby', you always remember 'Rails'? You should read this post...
categories:
  - Ruby
redirect_from:
  - /ruby/2015/10/05/ruby-is-not-only-rails/
---
Since the release of Rails framework, Ruby became the _language of the moment_. The easiness to create a complete web application in a short period of time and with low effort drove Rails to the top of rank, leading startups to exhaustively use it to create their prototypes and evolving them to a full product. Even big companies, such _Twitter_ and _Shopify_ have been benefited with the _new kid on the block_.

However, with such popularity, came another problem:

> Ruby has became just... Rails.

Some people have forgotten (or maybe didn't realised) that Rails is nothing more than a joint of Ruby gems working harmoniously.
The same easiness and productivity that drove Rails to its popularity is the one who's Rails foundations, which is Ruby. And this is horrible, because now, every problem, even the small ones, are great candidates do be implemented in Rails.

> _**Need to create a complete webapp, with bunch of models, controllers, validations, and a complex business logic?**_
>
> Do it with Rails...

> _**Need to implement a simple static blog?**_
>
> Do it with Rails as well...

> _**How much is 2 + 2?**_
>
> Oh, I really can't remember, but give me some minutes that I'll write a Rails app to figure it out...

This is similar to what happened with _JQuery_ and I really expect that don't happen again with _NodeJS_.

The purpose of this post is to show some alternatives to Rails framework and when one is more suitable than other in a given scenario.

So, let's start...

[Sinatra][sinatra-website]
---------------------------
Sinatra aims to be a lightweight option to create web applications with minimal effort. And by minimal, it really means minimal.

It provides a [DSL][dsl-wiki] which allows you to map routes to an specific URL and HTTP method. In other words, we can say:

> When I receive a GET request in _http://localhost/hello/{my name}_, I want to show the message _Hello {my name}_

So, the equivalent Sinatra code is:

{% highlight ruby %}
get '/hello/:name' do
puts "Hello #{name}"
end
{% endhighlight %}

> Now, when I receive a POST request in _http://localhost/sinatra/_, I want to show the message _Sinatra Rocks!_

{% highlight ruby %}
post '/sinatra/' do
puts "Sinatra Rocks!"
end
{% endhighlight %}

Easy, isn't?!

Of course, Sinatra alone can't do much, but using additional gems, Sinatra's power become unlimited.

> **Why Sinatra?**
>
> - Easy to learn (the DSL language is simple);
> - Lightweight;
> - Fast;
> - Scalable;
> - Extensible;

> **When to use it?**
>
> - When your problem is simple enough where using a full Rails stack isn't necessary;
> - When you want a simple response to given routes (great to mock third part services during your tests);

[Padrino][padrino-website]
--------------------------
As we saw before, Sinatra is a great framework to build simple web apps with low effort. However it implies that you must glue all the parts together manually, and this is such a pain in the #$@. To solve such problem, Padrino was released.

Padrino, in small words, is Sinatra with generators.

The whole framework runs over Sinatra, so the routes implementation is exactly the same in Sinatra, but the effort to configure the server, database, middleware, etc, is provided automatically in Padrino.

It gives built-in support to many useful features, such generators, mailers, logging, template renderer, localisation and even a simple administration tool, which helps a lot to control your system after the deploy.

> **Why Padrino?**
>
> All benefits inherited from Sinatra, plus:
>
> - Generators;
> - Bootstrap server configuration;

> **When to use it?**
>
> - When your problem isn't simple enough to do in Sinatra, but also not so complex to do in Rails;
> - When you want the power of a simple and fast framework such Sinatra but don't want to configure everything by hand;

[Lotus][lotus-website]
----------------------
Climbing a little more in the ladder, we have Lotus.

Lotus is a Ruby MVC framework which provides a syntax similar to Rails, but lightweight.

Is claims to bring back OO programming to Ruby web frameworks, something familiar to the ones that already know Rails.

Even sharing some similarities with Rails, Lotus foundations are much simpler, using Rake as its middleware.

We can see the similarities in the code below:

{% highlight ruby %}
# Defining a route mapping
get '/', to: 'home#index'

# Implementing the route handler
module Web::Controllers::Home
class Index
include Web::Action

    def call(params)
    end
end
end
{% endhighlight %}

As you can see, both route mapping and route handler looks really similar to Rails, which provides an easy migration for those who's already using Rails, with the advantage of having a clearer and lightweight system.

I haven't tested Lotus yet, but it's already on my list of things to study in future.

> **Why Lotus?**
>
> - Modular;
> - Reusable;
> - Easy deployment;
> - Testability;

> **When to use it?**
>
> - Need the power of Rails, but be able to choose which modules to use or not;


[Volt][volt-website]
--------------------
The last framework on this post is a very interesting one.

Volt is a **reactive web framework for Ruby**. For those who's updated with last tendencies on web development, reactive programming is gaining a lot of terrain in the last few years. Basically, it works oriented to **data flows** and **propagation of changes**. It means that a change in one part can reflect changes in the whole system, like an electrical circuit.

Instead of syncing data between server and client via HTTP requests, Volt uses a **persistent connection**. It means that data between client and server are kept updated whichever side changes. This works even with multiple clients. If you have 10 users connected simultaneously on the system, if one of them changes some state, the other 9 users and the server as well is notified and changes are propagated. You can learn more about reactive programming [here][reactive-programming-manifest].

Also, Volt runs Ruby code in both back and frontend, which, under the hood, compiles it to JavaScript using [Opal][opal-website]. With such architecture, Volt makes easy to handle user interactions in the system, updating the whole interface based on these changes and, if desired, persist these changes on cache and/or database. It's a great choice for those systems where data changes constantly in both ends, like a chat app, for example.

Volt is a great framework which aims to solve a big stack of problems using an intelligent and simple approach.

> **Why Volt?**
>
> - Based on reactive programming;
> - Ruby runs in both ends;

> **When to use it?**
>
> - When your system state changes constantly;
> - When you need to implement a real time app;

Conclusion
----------
Today, web development has reached a level of evolution that a single language or technology can't solve all problems. So, there are a lot of options to implement a system, each one with its specialties and weakness.

So, focusing on a single technology, just because it's the easiest or more famous one is a big mistake.

I'm not saying:

> Rails sucks! Never use it anymore!

The point is:

> Use Rails when Rails is the right choice. Otherwise, there are plenty of other approaches which can make your system simpler, faster and can save you a lot of development, tests and refactoring time.

[sinatra-website]: http://www.sinatrarb.com/
[padrino-website]: http://www.padrinorb.com/
[lotus-website]: http://http://lotusrb.org/
[volt-website]: http://voltframework.com/
[opal-website]: http://opalrb.org/
[reactive-programming-manifest]: http://www.reactivemanifesto.org/
[dsl-wiki]: https://en.wikipedia.org/wiki/Domain-specific_language
