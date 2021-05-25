---
title: "Nuke your AWS account, not your bank account"
excerpt: To be completed
date: 2021-06-01
categories:
  - AWS
---

Imagine the situation: 

You're new on the cloud space and are super excited, playing around with the new services you just learned.

As suggested on different blogs you visited, you set up a budget alarm, so you get an email when your bill surpass your pre-defined threshold.

You go to sleep and, next morning, notice that you got an email 8 hours ago: it's your budget alert. You go to your account and realize that you left an 
expensive service running through the night and it costed you more that you were expecting for a whole month.

Unlikely to happen? 

Well, it just happened to me some years ago, and I must say that I wasn't a complete beginner on AWS.

![](https://user-images.githubusercontent.com/11538662/119470388-94ff8200-bd48-11eb-9035-521fef2ba806.png)

AWS team was super comprehensive on my case and granted me credits to cover the bill, and checking online reports, this happened to some other folks as well. Still,
this is an unpleasant situation and something you want to avoid at all costs.

The cloud is very versatile and the range of possibilities it unfolds is endless. Still, some people refrain of jumping in this train due to the fear of getting a surprise bill out of nothing. At least if there was a way to stop your spending as soon you reach your limit.

In this post, I'll show you how to nuke yours AWS account when you reach your budget limit, so it doesn't nuke your bank account.

---

## Disclaimers

Before we start, it's important to clarify some points about our experiment and the solution we're building:

- This is a very destructive solution. It will delete many different resources in your account in order to stop your spending. If you cannot cope on losing data
on your AWS account, don't proceed (or at least proceed very carefully, so you know exactly what's being delete and what's not)
- This solution relies on a budget alarm setup in your account. Budget alarms aren't immediate, so there might be a delay when the nuke system is dispatched, which means your end bill can go above your defined threshold.
- The solution we're implementing here is fully serverless, which means no idle cost. You pay only by your utilization, which is insignificant and most of the time should fit in the free-tier (cost estimation available at the end of this article)

## The nuke system

Our system will be implemented as follows:

![Architecture diagram](https://user-images.githubusercontent.com/11538662/119465513-04bf3e00-bd44-11eb-877b-cd96e924dc14.png)

Everything starts with an AWS budget alarm. This alarm will be triggered when your spending surpass your specified threshold. EventBridge will be used to capture this alarm and trigger a CodeBuild project execution on response. CodeBuild, finally, will execute all the necessary steps to setup the environment, load your nuke configuration file (explained on the next chapter) and trigger aws-nuke, which will take care of deleting the resources in your AWS account.

## AWS Nuke

[rebuy-de/aws-nuke](https://github.com/rebuy-de/aws-nuke) is an OSS project that (as the name suggests), nuke your AWS account. This tool works by reading a configuration file defined by you and triggers a delete on all the resources you've allowed the tool to delete. _aws-nuke_ doesn't respect interdependency among services, it dispatches a delete request for all the resources sequentially. After that, a wait time is respect and nuke checks for the status of the deletion requests. Those who failed (e.g. because they're dependency of other services) are retried. The process remains until all the services are deleted or until there are only resources with errors left.

[assume-role-console-setup]: https://user-images.githubusercontent.com/11538662/107290201-6cd46780-6a66-11eb-81d0-c045b5e988e5.png

[assumed-role-console]: https://user-images.githubusercontent.com/11538662/107290205-6e059480-6a66-11eb-87f7-b68c185a8717.png