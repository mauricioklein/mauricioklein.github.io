# Mauricio Klein's Blog

My personal blog, using [NexT theme](next-github).


## How to run?

The easiest way is using Docker:

```bash
# Create the base image, with the dependencies pre-installed
$ docker build -t blog .

# Run the blog project, mounting the localhost directory
# as a volume on the container. This way, everytime a file
# is changed locally, Jekyll will automatically recompile
# the file inside the container
$ docker run --rm -v $(pwd):/app -p 4000:4000 -t blog
```

The blog can now be accessed on http://localhost:4000/.

## Layout information

Further layout information can be found on [theme's github project](next-github) and
on the [original README file](original-readme)

[next-github]: https://github.com/simpleyyt/jekyll-theme-next
[original-readme]: README.orig.md.
