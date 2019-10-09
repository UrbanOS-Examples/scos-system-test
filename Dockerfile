FROM bitwalker/alpine-elixir:1.8.1
ARG HEX_TOKEN
RUN apk update && \
  apk --no-cache --update upgrade alpine-sdk && \
  apk --no-cache add alpine-sdk && \
  rm -rf /var/cache/**/*
COPY . /app
WORKDIR /app
RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix hex.organization auth smartcolumbus_os --key ${HEX_TOKEN} \
  && mix deps.get \
  && mix format --check-formatted \
  && mix credo \
  && mix test
