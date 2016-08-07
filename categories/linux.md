---
layout: page
title: Linux
permalink: /categories/linux/
banner_image: tux.png
---

<div>
  {% assign post_counter = 0 %}

  {% for post in site.categories.Linux %}
    {% assign post_counter = post_counter | plus: 1 %}
    {% capture currentyear %}{{post.date | date: "%Y"}}{% endcapture %}

    {% if currentyear != year %}
      {% unless forloop.first %}
        </ul>
      {% endunless %}

      <h5>{{ currentyear }}</h5>
      <ul>

      {% capture year %}{{currentyear}}{% endcapture %}
    {% endif %}

    <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
  {% endfor %}

  {% if post_counter == 0 %}
    <h4>New posts comming soon!</h4>
  {% endif %}
