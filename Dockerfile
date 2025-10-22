FROM ruby:3.4-slim AS base

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RUBYOPT="--enable=frozen-string-literal"

RUN apt-get update


FROM base AS build

WORKDIR /build
RUN apt-get install -y \
    build-essential \
    libssl-dev

COPY Gemfile Gemfile.lock *.gemspec ./
COPY lib/ ./lib/
COPY bin/ ./bin/

RUN gem install bundler && \
    bundle install && \
    gem build *.gemspec && \
    gem install *.gem --no-document


# Final minimal image
FROM base
RUN apt-get install -y git-core \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
WORKDIR /app
CMD ["envirobly", "version"]
