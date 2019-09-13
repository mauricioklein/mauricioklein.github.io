---
title: "Chaos engineering: an introduction (1/2)"
date: 2019-08-16
excerpt: What's chaos engineering? How do I begin on it? Check it out...
categories:
- Chaos
---

> Saturday, 3AM.
>
> You're confortably on your bed, enjoying the well deserved rest of the modern worker. Then, sudenly, your duty phone rings: system is down!
>
> You wake up, sleepy, scratch your eyes and start the midnight investigation. Twenty minutes later, you realize the system went down because the EC2 instance running your service got terminated. You launch a new instance and the system is live again.
>
> Back to your bed, you start thinking:
>
> "why these stuff always happen during night, never on working time?"

Congratulations! You just discovered the motivation for Chaos engineering.

## What's chaos engineering

As stated by the [Principles of Chaos Engineering][principles-of-chaos], _Chaos engineering is the discipline of experimenting on a system in order to build confidence in the system’s capability to withstand turbulent conditions in production_.

In other words, Chaos engineering introduces failures and disturbance on a system, in a controlled manner, in order to assert the system resilience under unexpected conditions.

> _- OK, but what would be these "failures" and "disturbances"?_

Basically anything that can happen in a real world scenario: server crashes, network latency, attacks, etc. The idea behind chaos engineering is to put your system under abnormal situations and check how good it behaves.

> _- Fine! I'll shutdown my server and let's see what happens..._

Hold your horses, son!
Getting back to the definition of chaos engineering, let's highlight some important words:

- **Discipline**: chaos engineering isn't random. By being a discipline, it imposes definying some parameters for your experiment, like what's your hypothesis, how you evaluate the results, how to formulate conclusions, etc. Just randomly introducing failures on your system is dangerous and brings no value for your team and company.
- **Confidence**: while watching the world burn sounds like an interesting activity, chaos engineering has as main objective increasing confidence on your system. That means, if you know that shutting down the server will put your system down, what's the point of doing so, since you already knows the outcome of the experiment?

## How to formulate a chaos experiment?

So, a basic chaos experiment consists of three parts:

- **Steady-state definition**: the first step is define what's the steady-state of your system. This is a collection of metrics, such as response rate, error rate, latency, etc, that defines the baseline of your system under normal operation
- **Create your hypothesys**: the hypothesys defines that, under the stress situation, your system will remain in the steady-state. In other words, it suggests that your system will be resilient to a given failure
- **Try to disprove the hypothesis**: this is moment of truth: introducing the failures and disturbances, you'll check if the initial hypothesys is confirmed (i.e. system is resilient to such failure) or disproved (i.e. you system degrated due such failures).

On top of the basic checklist above, some extra important points to consider are:

- **Run in production**: as the name suggest, chaos engineering is supposed to bring chaos for the system, and chaos only happens in production. While totally feasible running a chaos experiment on testing environment, some scenarios only happen under real load, so always aim to run your experiments in production
- **Keep control all the time**: chaos experiments are supposed to put the system into avry situations, but if things get really ugly, make sure to have a fallback plan and put the system back in the steady state. Also, minimizing the angle of reach of your experiment is a good approach, so you only impact part of your system with the experiment. In this case, your non-affected portion of the system can be your steady-state control group.

> **_- Enough of chit chat! I wanna watch it burn..._**

Fair enough torchman.

On the part 2, let's make a quick experiment using AWS and see how chaos engineering can help us making our system more resilient.

[principles-of-chaos]: https://principlesofchaos.org/
