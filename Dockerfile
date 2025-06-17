# ─── Build Stage ─────────────────────────────────────────────────────
FROM hexpm/elixir:1.16.3-erlang-26.1.2-debian-bookworm-20250610 AS builder

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential git curl npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
ENV MIX_ENV=prod

# Install Hex and Rebar (package managers)
RUN mix local.hex --force && \
    mix local.rebar --force

# Pre-copy and compile deps (to cache them)
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config config
RUN mix deps.compile

# Copy remaining project files
COPY lib lib
COPY priv priv
COPY assets assets

# Compile and deploy assets
RUN mix esbuild.install --if-missing && \
    mix tailwind.install --if-missing && \
    npm --prefix ./assets ci && \
    mix assets.deploy

# Add remaining config and release
COPY config/runtime.exs config/
COPY rel rel

# Create the release
RUN mix release

# ─── Runtime Stage ───────────────────────────────────────────────────
FROM debian:bookworm-slim AS runner

# Install runtime dependencies
RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set working directory and app user
WORKDIR /app
RUN useradd -ms /bin/bash app && chown app /app
USER app

ENV MIX_ENV=prod

# Copy release from build stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/ims ./

# Set the default command to start the app
CMD ["/app/bin/ims", "start"]
