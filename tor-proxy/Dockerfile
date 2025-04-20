# === Stage 1: Build Tor ===
FROM alpine:latest AS builder

RUN apk add --no-cache \
    build-base \
    libevent-dev \
    openssl-dev \
    zlib-dev \
    asciidoc \
    gnupg \
    git \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    python3

WORKDIR /build

RUN git clone https://gitlab.torproject.org/tpo/core/tor.git && \
    cd tor && \
    ./autogen.sh && \
    ./configure --disable-asciidoc --disable-unittests --prefix=/tor-install && \
    make -j$(nproc) && \
    make install

# === Stage 2: Minimal runtime ===
FROM alpine:latest

RUN apk add --no-cache libevent openssl zlib

COPY --from=builder /tor-install /usr/local

# Beispielkonfiguration
RUN mkdir -p /etc/tor
COPY torrc /etc/tor/torrc

# Tor läuft unter eigenem Nutzer
RUN adduser -D -g 'Tor user' tor && \
    chown -R tor /etc/tor

USER tor

EXPOSE 9050 9051

ENTRYPOINT ["/usr/local/bin/tor", "-f", "/etc/tor/torrc"]
