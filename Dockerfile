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
# Pinned to the merge commit of nanvix/newlib#17 ("[libc] F: Weaken
# _do_start so libnvx_crt0.a can override it cleanly").  Update this
# SHA to the upstream merge commit before merging the present PR.
ARG NEWLIB_COMMIT=881840f880350e6fd929629cef9a5a3d1708bbf4
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

# Clone Newlib and pin to ${NEWLIB_COMMIT} (prior versions of this
# Dockerfile cloned with --depth=1 only and silently used the tip of
# ${NEWLIB_BRANCH} regardless of the declared pin, which made the
# build non-reproducible).  Fetching with sufficient depth and then
# checking out ${NEWLIB_COMMIT} restores the pin.
RUN git clone --branch ${NEWLIB_BRANCH} \
    https://github.com/nanvix/newlib /build/newlib && \
    cd /build/newlib && git checkout ${NEWLIB_COMMIT}

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
