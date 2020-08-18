---
title: "How Kanban helped me to organise my life"
date: 2018-05-11
excerpt: After a long time searching for a way to organise my life, the answer was right there, in Kanban
categories:
  - Life in IT
redirect_from:
  - /life%20in%20it/2018/05/11/kanban-daily-tasks/
---

After 10 years working in IT, I can say I'm pretty organised related to my tasks:
I can keep track of my productivity, plan my actions accordingly and, at the end of each sprint,
reflect about the mistakes and successes in the last two weeks.

But when I turn to my personal life, I can't see the same level of organisation:
emails waiting to be replied, German letters that need to be translated, groceries list... Any life
bureaucracy gets lost in a long and outdated Google Keep list, mixing done and to-do items.

Prioritising tasks? Pff, what a dream...

For some time things were quite working (messy, but working), until the mess become so big that my wife and me decided that something should be done about that.

So, I decided to find a definitive solution for that.

But what could I do? How can I put things under control again and give the necessary attention a topic deserves?

After reading some articles about life organisation and different techniques, I just realised:

> Wait a second: I'm organised... at work.
>
> Why can't I bring my daily work organisation and prediction to my life tasks?

That's where Kanban appears.

## Sprint stories x Life tasks

After some reflection, I realised that life tasks are pretty similar to sprint stories,
with the difference that you're also the stakeholder.

Sprint stories have dependencies, like story A depends on story B, the same way that buying a new vacuum cleaner depends on the research of available options in the market.

A Kanban backlog is prioritised, so the most urgent stories are attacked first, the same way that doing the groceries is more urgent than buying a new watch.

Keeping track about a sprint story discussion is as important as keeping track of the ping-pong email thread with the insurance company.

So, I decided to give a try and _Kanbanify_ my life.

## Trello

The tool chosen to keep track of my daily tasks was [Trello][trello] for the following reasons:

- It's free
- It's easy to use
- The board is clean and organised
- Has support to checklists, which can be useful to split the work of big tasks
- Has both desktop and mobile apps.

The whole thing was organised this way:

- A single board, containing all my tasks
- Each task is represented by a Trello card
- Four lists:
  - **Backlog**: as the name suggests, it's the entry point of all tasks
  - **Working**: the tasks being addressed at the moment
  - **Blocked**: tasks blocked due some dependency and/or waiting input/response from someone else
  - **Done**: the happy list, containing all the tasks finished
- Priority is defined using card's labels (only one per card, but this control is done manually, since Trello hasn't such feature):
  - **Nor urgent** (green)
  - **Important** (yellow)
  - **Urgent** (red)
- Backlog is sorted from the most to the least urgent tasks
- History is kept via card's comments

Here's a screenshot of my current _life board_ (unfortunately cards are described in Brazilian Portuguese):

![][mk-board]

## Results

After around a month, I can see the following results:

- I'm more efficient related to the life tasks. Everytime something gets done, I've a personal
  pleasure in moving the card to the `Done` list. In this sense, the board acts like some kind of reward system, because a clean board is a happy board :)
- I've full control about the state of my tasks. I can't remember how many times I had to scour
  my emails to find the last feedback about a task. With this new board, I've the entire history
  of a subject organised and directly available when I need.
- No more lost deadlines, since I can use the `due date` feature on Trello's card to remind me about
  that.
- Even my wife liked the idea and now she has her own board too. Most of the time she's the one who feeds my backlog, so I can no longer say I'm my own stakeholder :P

## Conclusion

The conclusion couldn't be better: I've full control about my life tasks again and the only thing
I did was apply some well know techniques in a different context. I'm now happier, because I don't have that daily stress anymore of getting things undone or lost in the limbo, and I've my `TODO` list directly on my browser or smartphone.

I've saw some similar approaches, like [this guy][github-life-tasks] who uses Github to control his list, but since Github is very technical (my wife would hate) and it imposes a premium account to keep the project private, Trello sounds like a more accessible solution.

The point is: no matter which tool you use (you can even use Jira, if you're masochistic enough), the idea works and can be a big turnaround for people who face the same kind of problem.

Worth to give it a try ;)

[trello]: https://trello.com/
[mk-board]: {{site.url}}/assets/images/posts_images/trello-life-screenshot.png
[github-life-tasks]: https://dev.to/und0ck3d/organizing-your-life-using-github-6an
