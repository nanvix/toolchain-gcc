# Copyright(c) The Maintainers of Nanvix.
# Licensed under the MIT License.

# =============================================================================
# nanvix/toolchain-gcc
#
# Cross-compilation toolchain: Binutils + GCC (2-stage) + Newlib for i686-nanvix.
#
# Build:
#   docker build -t ghcr.io/nanvix/toolchain-gcc:2.0.0 .
#
# Verify:
#   docker run --rm ghcr.io/nanvix/toolchain-gcc:2.0.0 i686-nanvix-gcc --version
# =============================================================================

FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        file \
        flex \
        gawk \
        git \
        libgmp-dev \
        libisl-dev \
        libmpc-dev \
        libmpfr-dev \
        m4 \
        make \
        patch \
        python3 \
        texinfo \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Pinned commits for each component.
ARG BINUTILS_COMMIT=686c3b0673c89fae3d03ee22a9d9ac9ce29bfa75
ARG GCC_COMMIT=d6995f34118ad2a5ed2f0408a3a8af44568bf2ee
ARG NEWLIB_COMMIT=e12d84a6789c07f938db4f6440ea0b427914c735
ARG NEWLIB_BRANCH=dev

ENV PREFIX=/opt/nanvix
ENV TARGET=i686-nanvix
ENV PATH="${PREFIX}/bin:${PATH}"

WORKDIR /build

# Clone Binutils.
RUN git clone https://github.com/nanvix/binutils /build/binutils && \
    cd /build/binutils && git checkout ${BINUTILS_COMMIT}

# Clone GCC.
RUN git clone https://github.com/nanvix/gcc /build/gcc && \
    cd /build/gcc && git checkout ${GCC_COMMIT}

# Clone Newlib.
RUN git clone --branch ${NEWLIB_BRANCH} --single-branch --depth=1 \
    https://github.com/nanvix/newlib /build/newlib

# Build Binutils.
RUN cd /build/binutils && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# Build GCC stage0 (bootstrap compiler, no libc).
RUN cd /build/gcc && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# Build Newlib (C library for target).
RUN cd /build/newlib && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# Build GCC stage1 (full compiler with libc support).
RUN cd /build/gcc && \
    ./z configure --install-location="${PREFIX}" --stage=1 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# =============================================================================
# Runtime stage — only the installed toolchain prefix.
# =============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal runtime dependencies for cross-compilation.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/nanvix /opt/nanvix

ENV PATH="/opt/nanvix/bin:${PATH}"

# Smoke test.
RUN i686-nanvix-gcc --version && \
    i686-nanvix-g++ --version && \
    i686-nanvix-as --version && \
    i686-nanvix-ld --version

LABEL org.opencontainers.image.source="https://github.com/nanvix/toolchain-gcc" \
      org.opencontainers.image.description="Nanvix GCC cross-compilation toolchain (Binutils + GCC + Newlib) for i686-nanvix"
