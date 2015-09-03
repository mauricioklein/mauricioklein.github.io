---
layout: post
title:  "Ruby isn't only Rails"
date: 2015-09-03 12:00:00
categories: Ruby
comments: true
excerpt: When you hear 'Ruby' always remember 'Rails'? You should read this post...
---
Since the release of Rails framework, Ruby became the _language of the moment_. The easiness to create a complete web application in a short period of time and with low effort driven Rails to the top of rank, leading startups to exhaustively use it to create their prototypes and evolving them to a full product. Even big companies, such Twitter and Shopify have been benefited with the _new kid on the block_.

However, with such popularity, come another problem: Ruby has became just... Rails.

Some people have forgotten (or maybe didn't realized) that Rails is nothing more than a joint of Ruby gems working harmoniously.
The same easiness and productivity that drove Rails to its popularity is the one who's Rails foundations, which is Ruby. And this is horrible, because now, every problem, if the small ones, are great candidates do been implemented in Rails.

Need to create a complete webapp, with bunch of models, controllers, validations, a complex business logic? Do it with Rails...

Need to implement a simple static blog? Do it with Rails as well...

How much is 2 + 2? Oh, I really can't remember, but give me some minutes that I'll write a Rails app to figure it out...

This is similar to what happened with JQuery and I really expect that don't happen again with NodeJS.

The purpose of this post is to show some alternatives to Rails framework and when one is more suitable than other in a given scenario.

So, let's start...

Sinatra
-------
[Sinatra][sinatra-website] aims to be a lightweight option to create web applications with minimal effort. And by minimal, it really means minimal.

It provides a [DSL][dsl-wiki] which allows you to map routes to an specific URL and HTTP method. In other words, we can say:

> When I receive a GET request in '/hello/foobar', I want to show the message 'Hello foobar'

So, the equivalent Sinatra code is:

{% highlight ruby %}
get '/hello/:name' do
   puts "Hello #{name}"
end
{% endhighlight %}

> Now, when I receive a POST request in '/sinatra/', I want to show the message 'Sinatra Rocks!'

{% highlight ruby %}
post '/sinatra/' do
   puts "Sinatra Rocks!"
end
{% endhighlight %}

Easy, isn't?!

Of course, only Sinatra we can't do much, but using additional gems, Sinatra power become unlimited.

When to use Sinatra?

- When your problem is simple enough where using a full Rails stack isn't necessary;
- When you want a simple response to given routes (great to mock third part services during your tests);

Why Sinatra?

- Easy to learn (the DSL language is simple);
- Lightweight;
- Fast;
- Scalable;
- Extensible;

[sinatra-website]: http://www.sinatrarb.com/
[dsl-wiki]: https://en.wikipedia.org/wiki/Domain-specific_language
