---
layout: post
title: Recovering a lost LightDM without Grub recovering option
date: 2017-01-19
categories: Linux
comments: true
---
This week I've been presented to the Pomodoro Technique: a way to improve your focus, splitting your daily time in small sprints, called Pomodoro.
If you're interested in know more about this, just check this post here :)

So, after getting in touch with the technique and decided that I would give a try with it, I've started searching for some app for Ubuntu
that control the Pomodoros for me. I've decided to use this one here.

During the instalation process, this package asked for me to select the login manager and, not being aware that lightdm is the default one, I've choose wrongly gdm, and
then my problems has begun.

After rebooting the machine, the loading screen freeze and, changing for the terminal view, I got that weird message:

> A start job is running for Hold until boot process finishes up (Xmin Xs/no limit)

After that I got it: I've messed the login manager...

So, my first try was to start the system in the recovery mode, but for some reason, this mode wasn't showing up on my Grub's menu.

So, what should we do on this case? Let's go to the hack...

## Booting in recovery mode
