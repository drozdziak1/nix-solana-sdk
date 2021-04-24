# syntax=docker/dockerfile:1.2
FROM rust:latest as rust-with-deps

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt update && apt -y upgrade && \
    apt-get install -y build-essential curl git libudev1

ENV SOL_RELEASE=v1.6.6
ENV TARGET=x86_64-unknown-linux-gnu

RUN git clone --branch=$SOL_RELEASE https://github.com/solana-labs/solana 

FROM rust-with-deps as rust-with-solana-built

WORKDIR solana

RUN --mount=type=cache,target=target --mount=type=cache,target=/root/.cargo cargo build -p solana-install 
