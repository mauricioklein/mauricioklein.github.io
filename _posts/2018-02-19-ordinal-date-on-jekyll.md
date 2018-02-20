---
title: "How to use ordinal date on Jekyll?"
date: 2018-02-19
excerpt: Check here how to use ordinal date on Jekyll
categories:
- Jekyll
---

I've been running my personal blog for more than three years now and, during this time, I've been relying on
[Jekyll][jekyll-website] as an easy and straight forward way to build my statics.

However, last week, I've faced a limitation on this setup: using ordinal dates.

## What's an ordinal date

For those who aren't aware, ordinal dates are very common on USA. It seems something like:

> January 3rd, 2018

Basically, after the day, it's added an ordinal suffix.

## The problem

Jekyll has support to a large range of custom date format. A full list of supported
formats and placeholders can be found [here][liquid-date-formatting].

However, ordinal dates aren't supported natively, since, under the hoods, Jekyll relies on Ruby's
[Time#strftime][strftime] method.

So, there must be a way to calculate the ordinal suffix manually and include it on the date.

## First approach: Jekyll plugin

The first and more straight forward way to solve this is using a Jekyll's plugin.

Checking Github, I've found [this plugin][ordinal-plugin], which is basically a Ruby implementation
of the ordinal date.

To use that, you only need to include the plugin file into the `_plugins/` directory and _voilà_, everything is
working, right?!

Almost...

Turns out that Github Pages doesn't allow custom plugins. It's a security measure adopted by Github team,
and you can find further information [here][github-custom-plugin-disclaim].

The workaround suggested by Github itself is to build the static files locally and, then,
push the branch.

This is not a big deal, but I like the convenience of pushing my branch to Github and just get the statics
build "automagically", so I don't have to bother about building it myself.

So, I've discarded this option.

## The solution

My workaround is using [Liquid][liquid-website] to calculate the ordinal suffix and use it as a regular
Jekyll template.

Basically, I've added the file `_includes/date.html` to my project, with the following content:

{% highlight liquid %}
  {% raw %}
    {% assign date = include.date %}
    {% assign format = include.format %}

    {% assign day = date | date: "%-d" %}

    {% capture day_ordinal %}
      {% case day %}
        {% when '1' or '21' or '31' %}{{ day }}st
        {% when '2' or '22'         %}{{ day }}nd
        {% when '3' or '23'         %}{{ day }}rd
        {% else                     %}{{ day }}th
      {% endcase %}
    {% endcapture %}

    {{ date | date: format | replace: '%o', day_ordinal }}
  {% endraw %}
{% endhighlight %}

This template expects two parameters: the date to be formatted and the desired template.

The trick lays on the last line: after the date is formatted, Liquid replaces all the `%o` occurrences
by the calculated ordinal day. That means, if we provide the template `%B %o, %Y`, the formatted
date will be something like `January 3rd, 2018`.

The `%o` is just a placeholder defined by myself. You can use anything you want, as long it
doesn't conflict with the ones supported by [Time#strftime][strftime].

Finally, to use this template, just add the following command, replacing `[date]` and `[format]`
by their respective values:

{% highlight liquid %}
  {% raw %}
    {% include date.html date=[date] format=[format] %}
  {% endraw %}
{% endhighlight %}

This can be a little verbose compared to the plugin approach, but I think it's a good tradeoff, considering I don't have to bother about building the static files manually :)

[strftime]: http://ruby-doc.org/core-2.2.1/Time.html#method-i-strftime
[ordinal-plugin]: https://github.com/patrickcate/Jekyll-Ordinal
[jekyll-website]: https://jekyllrb.com/
[liquid-website]: http://shopify.github.io/liquid/
[liquid-date-formatting]: https://learn.cloudcannon.com/jekyll/date-formatting/
[github-custom-plugin-disclaim]: https://help.github.com/articles/adding-jekyll-plugins-to-a-github-pages-site/
