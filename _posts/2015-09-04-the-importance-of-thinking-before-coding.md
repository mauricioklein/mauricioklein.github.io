---
layout: post
title:  "The importance of thinking before coding"
date: 2015-07-26 12:12:00
categories: Life
comments: true
---
The last week our _squad_ was responsable to fix a feature (already on production) that weren't given the expected result. Basically, this is the scenario:

We have a Camel route where we drop a lot of requests, and each request is consumed by a pool of consumer beans. The problem is: we have a limited time to process these requests. So, if the deadline is expired, the requests waiting to be executed are discarted, since they're no longer valid for the next day. So, to improve our revenue, it was decided to implement a sorting algorithm, using an heuristic to process the "most valuable" requests first.

After some meetings, the original algorithm was written.

Its logic is pretty simple: we do know, at the beginning of process, who many requests we will process. So, it was created a bean which store all requests in an internal structure and, when all the requests were arrived, they are sorted and dispatched.

After some time running (in production, since we hadn't an end to end environment to perform tests), it was seen that this algorithm have a lot o problems:

1. **The critical one**: if one single request is lost, all the other requests are blocked, since the batch isn't ready to be sorted yet. And, knowning the number of requests we process every day, the occurrence of this problem is pretty real.
2. Holding a large amount of requests in memory isn't the best suitable solution. It can leads to out of memory failures, performance degradation, etc.
3. Sorting all requests once, in the end of process, may be less efficient than storing them sorted dynamically.

All the problems described above could (and **must**) be avoided. Why aren't they?

The problem resides in a old and well know bad principle in software world: trying to reinvent the wheel.
