# Stage 1: Build
FROM hexpm/elixir:1.16.1-erlang-26.0-alpine-3.18 AS build

# Install build dependencies
RUN apk add --no-cache build-base git npm nodejs

# Set working directory
WORKDIR /app

# Set environment variables
ENV MIX_ENV=prod

# Install Hex + Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy mix and config files
COPY mix.exs mix.lock ./
COPY config config

# Fetch and compile deps
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets and build them
COPY assets assets
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets

# Digest static files
COPY priv priv
RUN mix phx.digest

# Copy source files
COPY lib lib

# Compile and build release
RUN mix compile
RUN mix release

# Stage 2: Runtime image
FROM alpine:3.18 AS app

# Install necessary runtime packages
RUN apk add --no-cache libstdc++ openssl ncurses-libs

# Set working directory
WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/ims ./

# Set default environment
ENV PHX_SERVER=true
ENV PORT=4000

# Start server
CMD ["bin/ims", "start"]
