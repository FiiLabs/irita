#
# Build image: docker build -t bianjie/metaosd .
#
FROM golang:1.19.3-alpine3.17 as builder

RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.17/main/ > /etc/apk/repositories
# this comes from standard alpine nightly file
#  https://github.com/rust-lang/docker-rust-nightly/blob/master/alpine3.12/Dockerfile
# with some changes to support CosmWasm toolchain, etc
RUN set -eux; apk add --no-cache ca-certificates build-base;

# Set up dependencies
# https://stackoverflow.com/questions/30624829/no-such-file-or-directory-limits-h-when-installing-pillow-on-alpine-linux
ENV PACKAGES make gcc git libc-dev bash openssl musl-dev

WORKDIR /irita

# Add source files
COPY . .

# Install minimum necessary dependencies
RUN apk add $PACKAGES

# NOTE: add these to run with LEDGER_ENABLED=true
# RUN apk add libusb-dev linux-headers

# See https://github.com/CosmWasm/wasmvm/releases
# ADD https://github.com/CosmWasm/wasmvm/releases/download/v0.16.0/libwasmvm_muslc.a /lib/libwasmvm_muslc.a
ADD image-deps/libwasmvm_muslc.a /lib/libwasmvm_muslc.a
RUN sha256sum /lib/libwasmvm_muslc.a | grep ef294a7a53c8d0aa6a8da4b10e94fb9f053f9decf160540d6c7594734bc35cd6

RUN go env -w GOPROXY=https://goproxy.cn
RUN LEDGER_ENABLED=false BUILD_TAGS=muslc make build
RUN apk del $PACKAGES
# ----------------------------

FROM ubuntu:20.04

# Set up dependencies
ENV PACKAGES build-essential perl wget

WORKDIR /

RUN echo 'deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse' > /etc/apt/sources.list
RUN echo 'deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse' >> /etc/apt/sources.list
RUN echo 'deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse' >> /etc/apt/sources.list


COPY image-deps/openssl-3.0.0-alpha4.tar.gz .

# Install openssl 3.0.0
# https://github.com/phusion/baseimage-docker/issues/319
RUN apt-get update && apt-get install $PACKAGES -y --no-install-recommends apt-utils \
    && tar -xzvf openssl-3.0.0-alpha4.tar.gz \
    && cd openssl-openssl-3.0.0-alpha4 && ./config \
    && make install \
    && cd ../ && rm -fr *openssl-3.0.0-alpha4* \
    && apt-get remove --purge $PACKAGES -y && apt-get autoremove -y

# p2p port
EXPOSE 26656
# rpc port
EXPOSE 26657
# metrics port
EXPOSE 26660

COPY --from=builder /irita/build/ /usr/local/bin/