---
title:  "How to change ORM in Padrino project"
date: 2015-07-26 19:26:00
categories:
- Ruby
---
I'm currently developing my graduation thesis (yeah, the end is near \o/).

I've decided to use this opportunity to explore a new technology, and the chosen one was **Padrino**.

[Padrino][padrino-website] is a Ruby framework built upon [Sinatra][sinatra-website]: Sinatra provides a simple DSL to create web applications and Padrino adds some useful tools to automate the creation of routes, models, anyway, the project's bootstrap.

One of the steps for creating a Padrino app is to choose an ORM. Padrino supports many ORMs, such ActiveRecord, MongoID, DataMapper, etc.

Well, in my project, I've choose ActiveRecord with Postgres. Why? Because I've had some familiarity with ActiveRecord from Rails.

Everything was going well, the system taking form but then, I've realised that a relational database wouldn't be the best choice for my problem.

So, I've decided to change from an ORM to a ODM (_object document mapping_), and the chosen one was MongoID + MongoDB.

The challenge now is: **how to move from ActiveRecord to MongoID?**

After some research, I've realised that Padrino doesn't provide an automated way to disable the old ORM and enable the new one. So, we need to do this manually.

_______

## 1. Creating a new Padrino project

Before we start our PoC, we need a Padrino project.
So, let's create a new one with the following commands:

{% highlight ruby %}
# Install Padrino gem
gem install padrino

# Create a new Padrino project, using:
# - RSpec as the test framework
# - ActiveRecord as the ORM;
# - Sqlite as the database
padrino g project padrino_orm_poc -t rspec -d activerecord
{% endhighlight %}

Padrino will create the project bootstrap, as expected.

Now, let's create our Models: **User** and **Post**

{% highlight ruby %}
# Change to Padrino project root
cd padrino_orm_poc

# Install necessary gems
bundle install

# Create User model, with:
# - Name;
# - Age;
padrino g model user name:string age:integer

# Create Post model, with:
# - Title;
# - Content;
padrino g model post title:string content:text
{% endhighlight %}

And then, preparing database to receive our models:

{% highlight ruby %}
# Edit config/database.rb to point to our Postgres database.
# (Here, 'postgres' points to my Postgres database IP. Change it to match your reality)
ActiveRecord::Base.configurations[:development] = {
  :adapter => 'sqlite3',
  :database => Padrino.root('postgres', 'padrino_orm_poc_development.db')
}

ActiveRecord::Base.configurations[:production] = {
  :adapter => 'sqlite3',
  :database => Padrino.root('postgres', 'padrino_orm_poc_production.db')
}

ActiveRecord::Base.configurations[:test] = {
  :adapter => 'sqlite3',
  :database => Padrino.root('postgres', 'padrino_orm_poc_test.db')
}

# Create database schema for the three environments:
# development, test and production
RACK_ENV=development rake db:create db:migrate
RACK_ENV=test rake db:create db:migrate
RACK_ENV=production rake db:create db:migrate
{% endhighlight %}

Now, we need to implement our models. So, here they are:

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

Now, let's make sure our models are interacting correctly. Let's create a simple test in User spec that:

1. Creates an user;
2. Creates 3 posts;
3. Associates posts to users;
4. Saves the user;

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

Now, let's run _rspec_ and see if everything is working as expected:

{% highlight bash %}
$ rspec

Pending: (Failures listed here are expected and do not affect your suite's status)

  1) Post add some examples to (or delete) /root/padrino/padrino_orm_poc/spec/models/post_spec.rb
     # Not yet implemented
     # ./spec/models/post_spec.rb:4

Failures:

  1) User Create a new user with posts
     Failure/Error: user.posts << post_1
     ActiveModel::MissingAttributeError:
       can't write unknown attribute `user_id`
{% endhighlight %}

Of course, we forgot to add an _user_id_ column on the Post's table, so the association is invalid.

Let's fix it:

{% highlight ruby %}
# Create the migration...
padrino g migration AddUserIdToModel

# ...set migration's content...
class AddUserIdToModel < ActiveRecord::Migration
  def change
    add_reference :posts, :user, index: true
  end
end

# ...and run migration in all 3 environments
RACK_ENV=development rake db:migrate
RACK_ENV=test rake db:migrate
RACK_ENV=production db:migrate
{% endhighlight %}

Running _rspec_ again:

{% highlight bash %}
$ rspec

Pending: (Failures listed here are expected and do not affect your suite's status)

  1) Post add some examples to (or delete) /root/padrino/padrino_orm_poc/spec/models/post_spec.rb
     # Not yet implemented
     # ./spec/models/post_spec.rb:4
{% endhighlight %}

It's saying that Post tests are missing. That's OK, because our test is implemented in User spec.
So, just delete _spec/models/post_spec.rb_ and run _rspec_ again:

{% highlight bash %}
$ rspec

.

Finished in 0.12314 seconds (files took 0.4811 seconds to load)
1 example, 0 failures
{% endhighlight %}

Great! We now have a simple Padrino project, running with two models (_User_ and _Post_), a simple test with RSpec
and using ActiveRecord + Sqlite.

It's time to move to MongoID...

_______

## 2. Adding MongoID support

Moving from ActiveRecord to MongoID is a three step work:

1. Add support to MongoID;
2. Adjust project for using MongoID instead of ActiveRecord;
3. Remove ActiveRecord from project;

_______

### 2.1. Adding support to MongoID

In order to use MongoID on your project, we basically need to:

1. Install MongoID gem;
2. Create connection to MongoDB database;

So, let's do it:

{% highlight ruby %}
# First of all, add the following line to you Gemfile...
gem 'mongoid'

# ...and then, rerun bundle install
bundle install
{% endhighlight %}

The next step is change _.components_ file to use MongoID instead of ActiveRecord. So, modify this file as following:

{% highlight ruby %}
# Replace this line...
:orm: activerecord

# ...by this one
:orm: mongoid
{% endhighlight %}

Now, we need to create _config/mongoid.yml_ file. This file is used to configure MongoDB connections used on
our project. It's like the _config/database.rb_ for ActiveRecord.

So, create the _config/mongoid.yml_ file with the following content:

{% highlight ruby %}
# Here, I have 'mongo' pointing to my MongoID database IP
# (Change this value to match your reality).
development:
  sessions:
    default:
      database: mongoid
      hosts:
        - mongo:27017

test:
  sessions:
    default:
      database: mongoid
      hosts:
        - mongo:27017

production:
  sessions:
    default:
      database: mongoid
      hosts:
        - mongo:27017
{% endhighlight %}

And, finally, create a new connection with MongoDB. So:

{% highlight ruby %}
# In lib/connection_pool_management.rb, remove this line...
ActiveRecord::Base.connection_pool.with_connection { @app.call(env) }

# ...and, in config/boot.rb, add these lines AFTER THE LAST 'REQUIRE' STATEMENT
require 'mongoid'
Mongoid.load!('config/mongoid.yml', RACK_ENV)
{% endhighlight %}

Ok, now we have MongoID enabled in our project.

It's time to adjust our models to use MongoID instead of ActiveRecord.

_______

### 2.2. Adjusting Models

We need to remove every reference to ActiveRecord from our models and replace it by the equivalent one for MongoID.

Let's do it:

{% highlight ruby %}
# Old User Model:
class User < ActiveRecord::Base
  has_many :posts
end

# New User Model
class User
  include Mongoid::Document
  field :name, type: String
  field :age, type: Integer

  embeds_many :posts
end

# Old Post Model:
class Post < ActiveRecord::Base
  belongs_to :user
end

# New Post Model:
class Post
  include Mongoid::Document
  field :title, type: String
  field :content, type: String

  embedded_in :user
end
{% endhighlight %}

And, finally, let's rerun _rspec_ and see if our modifications didn't break anything:

{% highlight bash %}
$ rspec

Finished in 0.0115 seconds (files took 0.66445 seconds to load)
1 example, 0 failures
{% endhighlight %}

**SUCCESS!!**

We now have our Padrino project running with MongoID + MongoDB \o/

Now, it's time to clean up the house, removing ActiveRecord.

_______

### 2.3. Getting rid of ActiveRecord

To remove ActiveRecord, we need to:

{% highlight ruby %}
# Delete the following resources...
config/database.rb
db/
postgres/

# ...remove this line from Rakefile...
PadrinoTasks.use(:activerecord)

# ...and these lines from Gemfile:
gem 'activerecord'
gem 'sqlite3'
{% endhighlight %}

Now, rerun _bundle install_ and a last _rspec_ to make sure everything is still working:

{% highlight bash %}
$ bundle install
$ rspec

.

Finished in 0.00805 seconds (files took 0.52411 seconds to load)
1 example, 0 failures
{% endhighlight %}

**CONGRATULATIONS!**

You have moved your project from _ActiveRecord + Sqlite_ to _MongoID + MongoDB_ \o/\o/\o/

_______

## Conclusion

Padrino is a great framework for those who wants to enjoy the power of Sinatra without needing to configure everything manually.
However, even with a large number of generators and many useful tools that save you a lot of development time, there are situations where you will need to roll up your sleeves and dive into Padrino's internals. In those cases, Padrino and Sinatra's documentation are your good allies.

And, if nothing else works, well, just leave the gun and take the cannoli.

> The project used in this tutorial is available on Github. You can access it [here][padrino-project]

[padrino-website]: http://www.padrinorb.com/
[sinatra-website]: http://www.sinatrarb.com/
[padrino-project]: https://github.com/mauricio-klein-blog-examples/padrino-orm-poc
