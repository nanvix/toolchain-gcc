# nanvix/toolchain-gcc

Cross-compilation toolchain for Nanvix: **Binutils + GCC (2-stage) + Newlib** targeting `i686-nanvix`.

## Overview

This repository builds and publishes a Docker image containing the complete GCC-based cross-compilation toolchain for Nanvix. The toolchain is installed under `/opt/nanvix/toolchain-gcc/` and includes:

- `i686-nanvix-gcc`, `i686-nanvix-g++` — C/C++ cross-compilers
- `i686-nanvix-as`, `i686-nanvix-ld` — assembler and linker
- `i686-nanvix-ar`, `i686-nanvix-objcopy`, etc. — binary utilities
- Newlib C library headers and libraries for the `i686-nanvix` target

## Usage

```bash
# Pull the image.
docker pull ghcr.io/nanvix/toolchain-gcc:2.0.0

# Cross-compile a C program.
docker run --rm -v $(pwd):/src ghcr.io/nanvix/toolchain-gcc:2.0.0 \
    i686-nanvix-gcc -o /src/hello /src/hello.c
```

## Building Locally

```bash
docker build -t ghcr.io/nanvix/toolchain-gcc:2.0.0 .
```

## Versioning

This repository follows independent semantic versioning starting at `1.0.0`. Version bumps here do **not** require a version bump in the main `nanvix/nanvix` repository — only the `build/toolchain-manifest.toml` pin needs updating.

## Pinned Upstream Commits

| Component | Repository | Commit |
|-----------|-----------|--------|
| Binutils | [nanvix/binutils](https://github.com/nanvix/binutils) | `07ea3ea` |
| GCC | [nanvix/gcc](https://github.com/nanvix/gcc) | `f250c8b` |
| Newlib | [nanvix/newlib](https://github.com/nanvix/newlib) | `e12d84a` |

## License

MIT — see [LICENSE.txt](LICENSE.txt).
