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

# Nanvix OS release providing libposix.a, user.ld, and nanvixd binaries that the
# GCC build's `z configure` step expects to be present in the install prefix.
# Keep these values in sync with the constants in nanvix/gcc's `z` script.
ARG NANVIX_RELEASE_TAG=v0.13.17
ARG NANVIX_RELEASE_ASSET=nanvix-x86-microvm-multi-process-release-128mb-0e7fd7c481527808d45df4559b666fe62de487d7.tar.bz2
ARG NANVIX_RELEASE_SHA256=eeb9686fca184944cdc6f8701796d0988df3f80d9e4dd84d3040238452fd8687

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

# Pre-fetch Nanvix OS artifacts (libposix.a, user.ld, nanvixd binaries) into the
# install prefix. The GCC `z configure` step downloads these from the public
# nanvix/nanvix release via `gh`, which is not available inside this build
# environment; staging them here makes `z` detect them and skip that download.
RUN set -eux; \
    url="https://github.com/nanvix/nanvix/releases/download/${NANVIX_RELEASE_TAG}/${NANVIX_RELEASE_ASSET}"; \
    tmp="$(mktemp -d)"; \
    curl -fsSL -o "${tmp}/nanvix-os.tar.bz2" "${url}"; \
    echo "${NANVIX_RELEASE_SHA256}  ${tmp}/nanvix-os.tar.bz2" | sha256sum -c -; \
    tar -xjf "${tmp}/nanvix-os.tar.bz2" -C "${tmp}"; \
    mkdir -p "${PREFIX}/lib" "${PREFIX}/libexec/nanvixd"; \
    install -m 644 "${tmp}/lib/libposix.a" "${PREFIX}/lib/"; \
    install -m 644 "${tmp}/lib/user.ld" "${PREFIX}/lib/"; \
    install -m 755 "${tmp}/bin/nanvixd.elf" "${PREFIX}/libexec/nanvixd/"; \
    install -m 755 "${tmp}/bin/kernel.elf" "${PREFIX}/libexec/nanvixd/"; \
    install -m 755 "${tmp}/bin/linuxd.elf" "${PREFIX}/libexec/nanvixd/"; \
    install -m 755 "${tmp}/bin/uservm.elf" "${PREFIX}/libexec/nanvixd/"; \
    rm -rf "${tmp}"

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
