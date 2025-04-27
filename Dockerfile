FROM alpine:3.21 AS builder

ARG BITCOIN_VERSION=29.0
ARG ZMQ_VERSION=4.3.5
ARG LIBEVENT_VERSION=2.1.12-stable

RUN apk add --no-cache \
    build-base \
    cmake \
    autoconf \
    automake \
    libtool \
    pkgconf \
    boost-static \
    boost-dev \
    openssl-dev \
    openssl-libs-static \
    sqlite-dev \
    sqlite-static \
    git \
    curl \
    tar

# --- ZeroMQ statisch bauen und installieren ---
WORKDIR /tmp
RUN curl -L https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}/zeromq-${ZMQ_VERSION}.tar.gz | tar xz
WORKDIR /tmp/zeromq-${ZMQ_VERSION}
RUN ./configure --enable-static --disable-shared --prefix=/usr && make -j$(nproc) && make install

# libevent statisch bauen
WORKDIR /tmp
RUN curl -LO https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz \
    && tar xzf libevent-${LIBEVENT_VERSION}.tar.gz
WORKDIR /tmp/libevent-${LIBEVENT_VERSION}
RUN ./configure --disable-shared --enable-static --prefix=/usr && make -j$(nproc) && make install

# Bitcoin Core holen
WORKDIR /
RUN curl -L https://github.com/bitcoin/bitcoin/archive/refs/tags/v${BITCOIN_VERSION}.tar.gz | tar xz
WORKDIR /bitcoin-${BITCOIN_VERSION}
RUN mkdir build

RUN cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_GUI=OFF \
        -DENABLE_WALLET=OFF \
        -DENABLE_ZMQ=ON \
        -DENABLE_BENCH=OFF \
        -DENABLE_TESTS=OFF \
        -DCMAKE_EXE_LINKER_FLAGS="-static" \
        -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" 
        
RUN cmake --build build --target bitcoind
RUN strip build/bin/bitcoind

FROM scratch
COPY --from=builder /bitcoin-29.0/build/bin/bitcoind /bitcoind
ENTRYPOINT ["/bitcoind"]