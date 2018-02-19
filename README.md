# Mauricio Klein's Blog

My personal blog, using [NexT theme][next-github].


## How to run?

The easiest way is using Docker:

```bash
# Create the base image, with the dependencies pre-installed
$ docker build -t blog .

# Run the blog project, mounting the local directory as
# a volume on the container.
#
# The Docker image is configured to watch for file
# modifications. This way, every time a file
# is changed locally, Jekyll will automatically recompile
# the statics inside the container and serve them.
$ docker run --rm -v $(pwd):/app -p 4000:4000 -t blog
```

The blog can now be accessed on http://localhost:4000/.

## Layout information

Further information about the base layout can be found on [theme's project][next-github] and
on the [original README file][original-readme].

[next-github]: https://github.com/simpleyyt/jekyll-theme-next
[original-readme]: README.orig.md
