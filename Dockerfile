ARG ERLANG_IMAGE
ARG ELIXIR_IMAGE

#########################
###### Build Image ######
#########################

FROM --platform=$BUILDPLATFORM ${ELIXIR_IMAGE} AS builder

ENV MIX_ENV=prod \
  MIX_HOME=/opt/mix \
  HEX_HOME=/opt/hex

RUN mix local.hex --force && \
  mix local.rebar --force

WORKDIR /app

COPY mix.lock mix.exs ./
COPY config config

RUN mix deps.get --only-prod && \
  mix deps.clean --unused && \
  mix deps.compile

# COPY priv priv
COPY lib lib

RUN mix release

#########################
##### Release Image #####
#########################

FROM --platform=$BUILDPLATFORM ${ERLANG_IMAGE}

# elixir expects utf8.
ENV LANG=C.UTF-8

WORKDIR /opt/flampy
COPY --from=builder /app/_build/prod/rel/flampy ./
RUN chmod g+rwX /opt/flampy
RUN apk add --no-cache python3 py3-pip

LABEL org.opencontainers.image.source="https://github.com/mruoss/flampy"
LABEL org.opencontainers.image.authors="michael@michaelruoss.ch"

USER 1001

ENTRYPOINT ["/opt/flampy/bin/flampy"]
CMD ["start"]

