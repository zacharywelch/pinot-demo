FROM ruby:3.1-slim

WORKDIR /app

# Install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy producer script
COPY producer.rb .

# Run the producer script
CMD ["ruby", "producer.rb"]
