# ─── Build Stage ─────────────────────────────────────────────────────
FROM hexpm/elixir:1.16.3-erlang-26.1.2-debian-bookworm-20250610 AS builder

RUN apt-get update -y && \
    apt-get install -y build-essential git curl npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod && mix deps.compile

COPY lib lib
COPY priv priv
COPY assets assets

# Install and build assets
RUN mix esbuild.install --if-missing && \
    mix tailwind.install --if-missing && \
    npm --prefix ./assets ci && \
    mix assets.deploy

COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# ─── Runtime Stage ───────────────────────────────────────────────────
FROM debian:bookworm-slim AS runner

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN useradd -ms /bin/bash app && chown app /app
USER app

ENV MIX_ENV=prod

# Correct release folder: ims (not ims_v2)
COPY --from=builder --chown=app:app /app/_build/prod/rel/ims ./

CMD ["/app/bin/ims", "start"]
