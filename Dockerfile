FROM ruby

RUN gem install bundler:2.0.1
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

#COPY . .

CMD ["rspec", "-fd", "spec"]
