# Mauricio Klein's blog

## Running on Docker

This project includes a **Dockerfile**, which allows lift a Jekyll container with this project and test it locally before pushing to Github.
This container exposes port 4000 and expect a directory containing a valid Jekyll project on /root/jekyll.

So, to lift the blog locally, follow the steps bellow:

```bash
# Build the image
docker build -t jekyll-blog [Path do Dockerfile]

# Lift the environment, mapping to port 4000 on localhost:
docker run -p 4000:4000 -v $(pwd):/root/jekyll -d jekyll-blog
```

Now, the blog is accessible on [http://localhost:4000/](http://localhost:4000) :)

## License

(The MIT License)

Copyright (c) 2014 Gayan Virajith

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[jekyll]: http://jekyllrb.com
[df]: http://jekyllrb.com/docs/datafiles/
