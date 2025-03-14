FROM ruby:3.4-slim AS builder

WORKDIR /build
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock *.gemspec ./
COPY lib/ ./lib/
COPY bin/ ./bin/

ENV BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT="1"

RUN gem install bundler && \
    bundle install && \
    gem build *.gemspec

# Final minimal image
FROM ruby:3.4-slim
RUN apt-get update && apt-get install -y git-core \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /build/*.gem ./
RUN gem install *.gem && \
    rm *.gem

CMD ["envirobly", "version"]
