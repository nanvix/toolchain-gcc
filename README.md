# nanvix/toolchain-gcc (removed)

The GCC/Newlib consumer toolchain was removed from the supported Nanvix
infrastructure on 2026-07-13.

Active consumers must use the versioned Clang/LLVM SDK published by
[`nanvix/sdk`](https://github.com/nanvix/sdk). GitHub prohibits deletion of the
legacy package because one version exceeded 5,000 downloads, so the package is
private and this repository is archived. No compatibility or rollback path is
provided.

The former implementation remains available only in Git history for audit.
