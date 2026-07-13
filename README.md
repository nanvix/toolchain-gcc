# nanvix/toolchain-gcc (removed)

The GCC/Newlib consumer toolchain was removed from the supported Nanvix
infrastructure on 2026-07-13.

Active consumers must use the versioned Clang/LLVM SDK published by
[`nanvix/sdk`](https://github.com/nanvix/sdk). Every former container tag now
resolves to an inert empty image and all deletable historical versions are
removed. GitHub retains the package because one untagged immutable version
exceeded 5,000 downloads. This repository is archived and no functional
compatibility or rollback path is provided.

The former implementation remains available only in Git history for audit.
