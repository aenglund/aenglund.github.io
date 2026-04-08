FROM --platform=linux/amd64 ruby:3.1-alpine

RUN apk add --no-cache build-base libxml2-dev libxslt-dev git

RUN gem install bundler:2.3.25

WORKDIR /srv/jekyll

COPY Gemfile Gemfile.lock ./
RUN bundle install

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--watch", "--force_polling", "--host", "0.0.0.0"]
