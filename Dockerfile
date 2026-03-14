FROM ruby:3.3-alpine
WORKDIR /app
RUN apk add --no-cache sqlite-dev build-base
COPY Gemfile ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["bundle", "exec", "ruby", "app.rb"]
