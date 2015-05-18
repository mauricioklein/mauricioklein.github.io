FROM ruby:latest

#
# Setup NodeJS / Vim
#
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs vim

#
# Install Jekyll
#
RUN gem install jekyll

#
# Copy project to container
#
ADD . /root/jekyll

#
# Listen to port 4000
#
EXPOSE 4000

#
# Run Jekyll's server
#
WORKDIR /root/jekyll
CMD ["jekyll", "server"]
