FROM alpine:latest AS builder

# Base tools
RUN apk add --no-cache \
    build-base \
    perl \
    cmake \
    nasm \
    git \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    wget \
    linux-headers

# Versions
ARG BITCOIN_VERSION=28.1
ARG OPENSSL_VERSION=1.1.1w
ARG LIBEVENT_VERSION=2.1.12-stable
ARG BOOST_VERSION_DOT=1.88.0
ARG BOOST_VERSION=1_88_0

# Installation prefixes
ENV PREFIX_DIR=/usr/local
ENV LIBEVENT_DIR=${PREFIX_DIR}
ENV OPENSSL_DIR=${PREFIX_DIR}

WORKDIR /build

# Statische OpenSSL kompilieren
RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xzf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config no-shared no-dso --prefix=${OPENSSL_DIR} -fPIC && \
    make -j$(nproc) && \
    make install_sw

# Statische libevent kompilieren
RUN wget https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz && \
    tar xzf libevent-${LIBEVENT_VERSION}.tar.gz && \
    cd libevent-${LIBEVENT_VERSION} && \
    ./configure --disable-shared --enable-static CFLAGS="-fPIC -O2" --with-openssl=${OPENSSL_DIR} && \
    make -j$(nproc) && \
    make install

# --------- Boost (nur Header) ----------
    RUN wget https://archives.boost.io/release/${BOOST_VERSION_DOT}/source/boost_${BOOST_VERSION}.tar.gz && \
    tar xzf boost_${BOOST_VERSION}.tar.gz && mv boost_${BOOST_VERSION} /boost

# --------- Bitcoin Core Build ----------
    WORKDIR /src
    RUN git clone --branch v${BITCOIN_VERSION} --depth=1 https://github.com/bitcoin/bitcoin.git .
    RUN cd /src && \
        ./autogen.sh && \
        ./configure --disable-wallet --without-gui --disable-tests --disable-bench \
            --prefix=/opt/bitcoin \
            --with-boost=/boost \
            --with-openssl=${OPENSSL_DIR} \
            --with-libevent=${LIBEVENT_DIR} \
            --disable-shared \
            --enable-static \
            LDFLAGS="-static -L${OPENSSL_DIR}/lib -L${LIBEVENT_DIR}/lib" \
            CFLAGS="-static -I${OPENSSL_DIR}/include -I${LIBEVENT_DIR}/include" && \
        make -j$(nproc) && \
        make install

# --------- Minimal final container -----------
    FROM scratch
    COPY --from=builder /opt/bitcoin/bin/bitcoind /bitcoind
    COPY --from=builder /opt/bitcoin/bin/bitcoin-cli /bitcoin-cli
    # Optional: bitcoin.conf kopieren, falls notwendig/gewünscht
    COPY bitcoin.conf /bitcoin.conf
    ENTRYPOINT ["/bitcoind", "-conf=/bitcoin.conf"]