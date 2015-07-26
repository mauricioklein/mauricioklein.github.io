FROM ruby:latest

#
# Setup NodeJS / Vim
#
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs vim

#
# Install Jekyll
#
RUN gem install bundler

#
# Run bundle install
#
ADD Gemfile /root/
WORKDIR /root/
RUN bundle install

#
# Copy project to container
#
ADD . /root/jekyll
WORKDIR /root/jekyll

#
# Listen to port 4000
#
EXPOSE 4000
