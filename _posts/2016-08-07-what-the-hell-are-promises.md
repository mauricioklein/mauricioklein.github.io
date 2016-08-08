---
layout: post
title:  "What the hell are promises?"
date: 2016-08-07 10:56:00
categories: JavaScript
comments: true
excerpt: Tired of hearing about promises and getting in a haze? Don't worry, I'll introduce you to the party...
---

Probably you've already heard about the new kid on the block: promises.

But, what the heck is a promise?

Before we get in touch with this guy, let's contextualize the situation and understand where it's applicable.

_____

## Callbacks, callbacks and more callbacks

Let's suppose we have a time consuming operation, like a database access, parse some file, etc.
You, as a good programmer, won't let user waiting for this operation to finish. So, you decided to provide a callback to this time consuming method.

A callback is nothing more than a function that will be called once this time consuming operation has finished.

Just to exemplify this situation, let's consider the function below:

{% highlight javascript %}
// Callback success if time < 4000.
// Otherwise, callback error
const MAX_SUCCESS_TIME = 4000

const timeConsumingOperation = (id, success, error) => {
  // Generate a random value between 1000 and 5000
  // (used in interval)
  const time = Math.round((Math.random() * 4000) + 1000)

  setTimeout(() => {
    if (time < MAX_SUCCESS_TIME) success({id: id, time: time})
    else                         error  ({id: id, time: time})
  }, time)
}
{% endhighlight %}

The function above receives 3 arguments: an ID (used to identify the process), an two callbacks, one for success and other for error.

It generates a random value, between 1000 and 5000 (1 and 5 seconds). This value is then send to *setTimeout()* method.

After the timeout is complete, the appropriate callback is called:
if the time generate was less than 4000 (4 seconds), success callback is invoked.
Otherwise, error callback is invoked.

So, calling this time consuming function, as below...

{% highlight javascript %}
timeConsumingOperation(0,
  (result) => console.log(`Operation finished successfully in ${result.time}ms`),
  (error)  => console.log(`Operation finished unsuccessfully: ${error.time}ms > ${MAX_SUCCESS_TIME}ms`)
)
{% endhighlight %}

... we get as result after 3 executions:

{% highlight bash %}
Operation finished successfully in 3659ms
Operation finished successfully in 2274ms
Operation finished unsuccessfully: 4289ms > 4000ms
{% endhighlight %}

No problem until here.

But now, let's consider a more complex situation:

Let's suppose that you're registering a new user in you platform, and, so, you need to perform 3 time consuming operations:

* **Operation 1**: Create many records on database, like user profile, account, preferences, etc;
* **Operation 2**: Validate user credit card;
* **Operation 3**: Send welcome email;

So, let's use our new branch function with callbacks to perform that.

{% highlight javascript %}
timeConsumingOperation(1,
  (result) => {
    console.log(`Operation ${result.id} finished in ${result.time}ms`)
    timeConsumingOperation(2,
      (result) => {
        console.log(`Operation ${result.id} finished in ${result.time}ms`)
        timeConsumingOperation(3,
          (result) => {
            console.log(`Operation ${result.id} finished in ${result.time}ms`)
            console.log(`All 3 operations finished successfully in ${new Date().getTime() - initialTime}ms`)
          }
        )
      }
    )
  }
)
{% endhighlight %}

WOW, what a mess!

We have 3 main problems here:

* This is a clearly convoluted code, since, for each new call we add, another *step in the ladder* is added;
* We don't have error handling here. So, adding the error callback for each time consuming call will turn this code in a *spaghetti* (and this is not cool, even if this code is going to be used in an Italian restaurant website)
* The worst one: this algorithm is now **synchronous**, since the next call is just performed once the previous one is finished

There must be a better and cleaner way to do this...

Yes, it does, and this is called promises...

_____

## Promises

Promise is a technique to perform asynchronous operations in a **composable** way.

A promise, instead returning the result value of the operation, represents a operation that hasn't completed yet. It's like saying:

> I haven't finished my task yet but, as soon I do, I promise that I'll return a success or an error response.

A promise can be in 3 different states:

* **Pending**: not yet finished
* **Fulfilled**: execution finished with **success**
* **Rejected**: execution finished with **error**

Once a promise has its status changed to *fulfilled* or *rejected*, this is the final state.

_____

### Creating a promise

In order to create a promise, we simply instantiate a new promise object, passing 2 callbacks as arguments: the first one is the **resolve callback** and the seconds one is the **reject callback**. Check it out:

{% highlight javascript %}
function myBrandNewFunction() {
  return Promise.new((resolve, reject) => {
           if ([success]) resolve()
           else           reject()
         })
}
{% endhighlight %}

Now we have to handle the both situations: the *success (resolve)* and *failure (reject)*.

Success operations are handled by the method **then()**, while error operations are handled by the method **catch()**.

So, using our function *myBrandNewFunction()* as example:

{% highlight javascript %}
myBrandNewFunction()
  .then(()  => console.log('Promise resolved'))
  .catch(() => console.log('Promise rejected'))
{% endhighlight %}

In the example above, *myBrandNewFunction()* returns a promise. As soon this promise is created, it's in *pending* status, meaning that the execution isn't finished yet.

Since the execution is done, the function decides which callback call: the *resolve* one or the *reject*.

So, we now just need to treat each case: the success one (with *then()*) and the failure one (with *catch()*).

We can also chain *then()* calls, where the input of the current *then()* is a promise provided by the previous one.

For example:

{% highlight javascript %}
myBrandNewFunction()
  .then(() => {
    console.log('Log message 1')
    return Promise.resolve()
  })
  .then(() => {
    console.log('Log message 2')
    return Promise.resolve()
  })
  .then(() => {
    console.log('Log message 3')
    return Promise.reject()
  })
  .catch(() => console.log('Promise rejected'))
{% endhighlight %}

_____

## Back to our problem

So, now that we know what a promise is and what's its purpose, let's adjust our ugly algorithm to use promises and see the result.

Let's make our time consuming operation return a promise instead calling a callback:

{% highlight javascript %}
// Callback success if time < 4000
// Otherwise, callback error
const MAX_SUCCESS_TIME = 4000

const timeConsumingOperation = (id) => {
  // Generate a random value between 1000 and 5000
  // (used in interval)
  const time = Math.round((Math.random() * 4000) + 1000)

  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (time < MAX_SUCCESS_TIME) resolve({id: id, time: time})
      else                         reject ({id: id, time: time})
    }, time)
  })
}
{% endhighlight %}

Notice that our argument list has reduced from 3 to 1 element, because we don't need provide callbacks for this method anymore.

Now, let's handle the promise resolution:

{% highlight javascript %}
timeConsumingOperation(1)
  .then((result) => console.log(`Operation finished successfully in ${result.time}ms`))
  .catch((error) => console.log(`Operation ${error.id} failed: ${error.time}ms > ${MAX_SUCCESS_TIME}ms`))
{% endhighlight %}

A simple and clean solution :)

But, what about our last problem:

> Run 5 time consuming operations and log out a message when all of them finished successfully?

Well, no problem at all my friend!

Promises class provide a method called **all**, which basically waits for all promises to finished and, then:

* Resolve it, if all promises resolve, returning an array with all resolved values;
* Reject it, if at least one of them rejected, returning the reject value;

So, our *spaghetti* algorithm from the callback example can be simplified by this one, using promises:

{% highlight javascript %}
Promise.all([
  timeConsumingOperation(1),
  timeConsumingOperation(2),
  timeConsumingOperation(3)
])
.then ((results) => {
  results.forEach((result) => console.log(`Operation ${result.id} finished successfully in ${result.time}ms`))
})
.catch((error) => console.log(`Operation ${error.id} failed: ${error.time}ms > ${MAX_SUCCESS_TIME}ms`))
{% endhighlight %}

Now, our code is:

* **Callbacks free**: no more need to deal with callbacks. Promise handle that for us;
* **Not convoluted**: it's deadly easy to add more operations and handle their results;
* **Clean**: much more easy to understand the logic and maintain the code;
* **Asynchronous**: all operations are dispatched in parallel, and *Promise.all* takes care of controlling everything and resolving/rejecting each operation;

Promise class has a lot of other helpful methods. You can check all of them [here][promise-website].

_____

## Conclusion

Promises can be a little confusing in a first moment, but once you get familiar with the technique, it surely can be very helpful, allowing you to
write (or even rewrite) your algorithms in a much cleaner and maintainable way.

> All the examples presented here are available on [GitHub][github-project]

[promise-website]: https://www.promisejs.org/api/
[github-project]: https://github.com/mauricio-klein-blog-examples/promises-js
