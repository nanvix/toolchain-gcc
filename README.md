# nanvix/toolchain-gcc (removed)

The GCC/Newlib consumer toolchain was removed from the supported Nanvix
infrastructure on 2026-07-13.

Active consumers must use the versioned Clang/LLVM SDK published by
[`nanvix/sdk`](https://github.com/nanvix/sdk). All legacy container tags and
deletable versions are removed. GitHub retains one untagged immutable version
because it exceeded 5,000 downloads; it is inaccessible through a supported
tag. This repository is archived and no compatibility or rollback path is
provided.

The former implementation remains available only in Git history for audit.
