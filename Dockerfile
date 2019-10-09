FROM bitwalker/alpine-elixir:1.8.1
RUN apk update && \
  apk --no-cache --update upgrade alpine-sdk && \
  apk --no-cache add alpine-sdk && \
  rm -rf /var/cache/**/*
COPY . /app
WORKDIR /app
RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get \
  && mix format --check-formatted \
  && mix credo \
  && mix test
