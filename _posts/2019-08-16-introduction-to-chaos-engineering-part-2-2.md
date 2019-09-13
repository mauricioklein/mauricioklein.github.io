---
title: "Chaos engineering: an introduction (2/2)"
date: 2019-08-16
excerpt: What's chaos engineering? How do I begin on it? Check it out...
categories:
- Chaos
---

> This is the part 2 of _Chaos engineering: an introduction._
>
> Make sure to check the [part 1][part-1] before proceeding :)

So, there are many different chaos libraries and frameworks available. You probably already heard about the most famous one, [Chaos Monkey][chaos-monkey], created by Netflix. But today we're using something different: we are going to use [Chaos Toolkit][chaos-toolkit], which is a community-driver chaos framework, written in Python. The cool part about Chaos Toolkit is that it's modular, being extended by Python modules created and maintained by the community. So, let's start...

# Version 1: Our simple webpage

[part-1]: /chaos/2019/08/16/introduction-to-chaos-engineering-part-1-2/
[chaos-monkey]: https://github.com/Netflix/chaosmonkey
[chaos-toolkit]: https://chaostoolkit.org/
