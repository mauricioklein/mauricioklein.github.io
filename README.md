![Daily Build](https://github.com/mauricioklein/mauricioklein.github.io/workflows/Daily%20Build/badge.svg)

# [mklein.io](https://mklein.io)

My personal blog, using [NexT theme][next-github].


## How to run?

The easiest way is using Docker:

```bash
# Create the base image, with the dependencies pre-installed
$ make image

# Run the blog project, mounting the local directory as
# a volume on the container.
#
# The Docker image is configured to watch for file
# modifications. This way, every time a file
# is changed locally, Jekyll will automatically recompile
# the statics inside the container and serve them.
$ make watch

# Run the blog project, opening a bash console
# in the container (useful for development/debugging)
$ make console
```

The blog can now be accessed on http://localhost:4000/.

## Layout information

Further information about the base layout can be found on [theme's project][next-github] and
on the [original README file][original-readme].

[next-github]: https://github.com/simpleyyt/jekyll-theme-next
[original-readme]: README.orig.md
