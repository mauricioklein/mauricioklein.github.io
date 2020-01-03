---
title: "Profiling Zsh startup time"
date: 2020-01-03
excerpt: Zsh taking a long time to start? Let's find out the reason...
---

I have been using [Zsh][zsh] (with [Oh My Zsh][oh-my-zsh]) for some time already. Among all the cool available features, the one I use the most for sure is custom plugins.
It basically allows you to define custom commands, functions, etc, in _.zsh_ files and, if placed in the right path, they're automatically loaded by ZSH on the startup time.
This is very handy to define and organize shortcuts for different purposes. I have custom plugins for AWS commands, Terraform, Kubernetes, etc.

But, after some time, I started noticing that Zsh was taking more time than usual to load the session. In my case, it was taking ~3s between the terminal is dispatched and the console becomes active.
Three seconds might not sound like a big deal, but multiply by the "n" times a new session is started in a day and this can become really annoying. So, I decide to do some profiling.

## Profiling ZSH

So, my first problem was: I've dozens of custom plugins. How to find out which one is taking more time?

The first approach would be add a time check per plugin, and see which one is consuming the majority of time. But there must be an easier way. And indeed there is.

Turns out Zsh is shipped with a native module for profiling, called `zprof`. This module gives you a list of all the modules loaded during Zsh startup, including time consumed during the load, CPU usage, etc.

So, first, we need to include the module. This can be done by including the `zprof` directive on _~/.zshrc_ file:

```zsh
# ~/.zshrc
zmodload zsh/zprof

[The rest of your .zshrc file]
```

Now open a new Zsh session (or reload the current one) and, as soon the startup is done, run the profiler:

```
$ zprof
```

![][zprof-original]

OK, I think we have a candidate for greedy plugin.

The first four entries of `zprof` are reporting load operations on `NVM` plugin. `NVM` stands for `NodeJS Version Manager` and, summing up the four entries, this single step is consuming ~80% of the CPU core power during the startup time,
resulting in ~1.5s extra.

So, I went checking my custom plugin and found this snippet:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

I hardly use NVM to be honest (it was legacy from an old project), so in my case I'll just drop it completely.

Now, let's see the `zprof` output when reloading the session without the `NVM` completion:

```bash
$ source ~/.zshrc
$ zprof
```

![][zprof-no-nvm]

`NVM` is gone and we saved around ~1.5s only by removing an eager loaded plugin.

Now, our top cpu-consuming plugin is related to `kubectl`. Unfortunately `zprof` doesn't inform exaclty which Bash command originated the plugin load, so here we need to do some investigation.

My guest is that, by the function name (`_kubectl_bash_source`), it's probably a bash autocompletion for `kubectl`.

So, after some investigation, I found out the cause:

```bash
if [ $commands[kubectl] ]; then
    source <(kubectl completion zsh)
    complete -F __start_kubectl k
fi
```

As suspected, this is a bash autocomplete for `K8s` resources. I work with K8s in a `daily` basis, so I can't just drop this. However, I can make it not load on every session startup, because sometimes I don't need to interact with
K8s in the console, like when I'm doing something related to Cloudformation (or AWS in general). So, the naive solution is move this autocomplete loading for a function and invoke it when I need to use K8s:

```bash
function load-k8s-completion {
    source <(kubectl completion zsh)
    complete -F __start_kubectl k
}

# And invoke the function when needed:
$ load-ks8-completion
```

Again, let's reload the session and check `zprof` output:

```bash
$ source ~/.zshrc
$ zprof
```

![][zprof-no-k8s-completion]

You can keep going as deep as you can, removing or moving around plugins that are impacting the startup time of your session.



[zsh]: https://www.zsh.org/
[oh-my-zsh]: https://github.com/ohmyzsh/ohmyzsh
[zprof-original]: {{site.url}}/assets/images/posts_images/zsh-profiling/zprof-original.png
[zprof-no-nvm]: {{site.url}}/assets/images/posts_images/zsh-profiling/zprof-no-nvm.png
[zprof-no-k8s-completion]: {{site.url}}/assets/images/posts_images/zsh-profiling/zprof-no-k8s-completion.png
