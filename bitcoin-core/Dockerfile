# Stage 1: Build Bitcoin Core
FROM debian:bookworm-slim AS builder

LABEL org.opencontainers.image.title="Bitcoin Core"
LABEL org.opencontainers.image.description="Minimal Bitcoin Core container with automatic config, rpcauth, healthcheck, and watchdog"
LABEL org.opencontainers.image.version="28.1"
LABEL org.opencontainers.image.url="https://github.com/bitcoin/bitcoin"
LABEL org.opencontainers.image.authors="Bitcoin Core Maintainers <maintainers@bitcoin.org>"
LABEL org.opencontainers.image.license="MIT"
LABEL org.opencontainers.image.release="v1.0"
LABEL org.opencontainers.image.authors="Sven Lidynia <sven@lidynia.de>"

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential libtool autotools-dev automake pkg-config bsdmainutils curl git ca-certificates \
    python3 python3-pip libboost-all-dev libevent-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone Bitcoin Core repository
RUN git clone https://github.com/bitcoin/bitcoin.git

WORKDIR /build/bitcoin

# Checkout stable version
RUN git checkout v24.0  # oder die Version, die du verwenden möchtest

RUN ./autogen.sh && ./configure --disable-wallet --without-gui --disable-tests --disable-bench --with-incompatible-bdb \
    --prefix=/opt/bitcoin --with-gui=no --enable-static --disable-shared

RUN make -j$(nproc) && make install

# Stage 2: Runtime image
FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Bitcoin Core"
LABEL org.opencontainers.image.description="Minimal Bitcoin Core container with automatic config, rpcauth, healthcheck, and watchdog"
LABEL org.opencontainers.image.version="28.1"
LABEL org.opencontainers.image.url="https://github.com/bitcoin/bitcoin"
LABEL org.opencontainers.image.authors="Bitcoin Core Maintainers <maintainers@bitcoin.org>"
LABEL org.opencontainers.image.license="MIT"
LABEL org.opencontainers.image.release="v1.0"
LABEL org.opencontainers.image.authors="Sven Lidynia <sven@lidynia.de>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash python3 curl ca-certificates libevent-dev gosu \
    && rm -rf /var/lib/apt/lists/*

# Copy the built Bitcoin Core from the builder stage
COPY --from=builder /opt/bitcoin /opt/bitcoin
ENV PATH="/opt/bitcoin/bin:$PATH"

WORKDIR /data

# Copy entrypoint and watchdog scripts
COPY entrypoint.sh /entrypoint.sh
COPY watchdog.sh /watchdog.sh
RUN chmod +x /entrypoint.sh /watchdog.sh

# Healthcheck command
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD bitcoin-cli -datadir=/data getblockchaininfo || exit 1

ENTRYPOINT ["/entrypoint.sh"]