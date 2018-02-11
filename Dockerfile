from ruby:2.5.0

ENV APP_PATH /app

RUN mkdir -p $APP_PATH

WORKDIR $APP_PATH

ADD Gemfile* $APP_PATH/

RUN ["/usr/local/bin/gem", "install", "bundler"]
RUN ["bundle", "install"]

EXPOSE 4000

ENTRYPOINT ["bundle", "exec", "jekyll", "server", "-P", "4000", "-H", "0.0.0.0"]
