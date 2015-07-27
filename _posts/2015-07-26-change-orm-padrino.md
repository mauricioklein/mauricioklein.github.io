---
layout: post
title:  "How to change ORM in Padrino project"
date: 2015-07-26 19:26:00
categories: Ruby
comments: true
excerpt: Have a Padrino project and wanna change ORM?! Check here how to do that...
---
I'm currently developing my graduation thesis (yeah, the end is near \o/).

I've decided to use this oportunity to explore a new technology, and the chosen one was **Padrino**.

[Padrino][padrino-website] is a Ruby framework built upon [Sinatra][sinatra-website]: Sinatra provides a simple DSL for create web applications and Padrino add some usefull tools to automate the creation of routes, models, well, the project bootstrap.

One of the steps while creating a Padrino app is to choose an ORM. Padrino support many ORMs, such ActiveRecord, MongoID, DataMapper, etc.

Well, in my project, I've choose ActiveRecord with Postgres. Why? Because II had some familiarity with ActiveRecord from Rails.
Everything was going well, the system taking form but than, I realized that a relational database wouldn't be the best choice for my problem.
So, I've decided to change from an ORM to a ODM (_object document mapping), and the chosen one was MongoID + MongoDB.

The challenge now is: how to choose from ActiveRecord to MongoID?

After some research, I realized that Padrino doesn't provides an automated way to disable the old ORM and enable the new one. So, we need to do this manually.

_______

## 1. Creating a new Padrino project

Before we start our PoC, we need a Padrino project.
So, let' create a new one with the following commands:

{% highlight ruby %}
# Install Padrino gem
gem install padrino

# Create a new Padrino project, using:
# - RSpec as test framework
# - ActiveRecord as ORM;
# - Sqlite as database
padrino g project padrino_orm_poc -t rspec -d activerecord
{% endhighlight %}

Padrino will create the project bootstrap, as expected.

Now, let's create our Models: **User** and **Post**

{% highlight ruby %}
# Create User model, with:
# - Name;
# - Age;
padrino g model user name:string age:integer

# Create Post model, with:
# - Title;
# - Content;
padrino g model post title:string content:text
{% endhighlight %}

And then, to prepare database to receive our models:

{% highlight ruby %}
# Create database schema for the three environments: development, test and production
RACK_ENV=development rake db:create db:migrate
RACK_ENV=test rake db:create db:migrate
RACK_ENV=production rake db:create db:migrate
{% endhighlight %}

Now, we need to fulfill our models. So, here they are:

{% highlight ruby %}
# User Model
class User < ActiveRecord::Base
  has_many :posts
end

# Post Model
class Post < ActiveRecord::Base
  belongs_to :user
end
{% endhighlight %}

Now, let's assure our models are interacting correctly. Let's create a simple test in User spec that:
1. Create an user;
2. Create 3 posts;
3. Associate posts to users;
4. Save;

So, here is the test code (_spec/models/user.rb_):

{% highlight ruby %}
require 'spec_helper'

RSpec.describe User do
  context 'Create a new user' do
    it 'with posts' do
      user = User.new(name: 'John', age: 25)
      user.save!

      post_1 = Post.new(title: 'Post title 1', content: 'Post 1 content')
      post_2 = Post.new(title: 'Post title 2', content: 'Post 2 content')
      post_3 = Post.new(title: 'Post title 3', content: 'Post 3 content')

      user.posts << post_1
      user.posts << post_2
      user.posts << post_3
      user.save!

      # Load user from database
      user = User.find(user.id)
      expect(user.posts.length).to eq(3)
    end
  end
end
{% endhighlight %}

Running _rspec_ we see our test is passing.

Ok, we have a Padrino project, two models interacting among them and a test to validate everything.

It's time to move to MongoID...

_______

## 2. Adding MongoID support

padrino g project padrino_orm_poc -t rspec -d activerecord
bundle install
padrino g model user name:string age:integer
padrino g model post title:string content:text
rake db:create db:migrate
padrino g migration AddUserReferenceToPost
RACK_ENV=test rake db:create db:migrate
rspec

gem install

[padrino-website]: http://www.padrinorb.com/
[sinatra-website]: http://www.sinatrarb.com/
