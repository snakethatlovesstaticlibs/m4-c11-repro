#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p logs
bazel --version

if bazel build //:m4 >logs/failure.log 2>&1; then
    echo "Unexpected success: the m4 failure was not reproduced." >&2
    exit 1
fi

if ! grep -q "implicit declaration of function 'alignof'" logs/failure.log; then
    tail -60 logs/failure.log >&2
    echo "Build failed for a different reason." >&2
    exit 1
fi

grep -A 7 "implicit declaration of function 'alignof'" logs/failure.log
repro_bin=$(bazel info bazel-bin)
grep -n '^#define HAVE_C_ALIGNASOF 1' "$repro_bin/external/m4+/lib/config.h"
echo "Reproduced: C23 feature detection enabled HAVE_C_ALIGNASOF, but m4 compiles as C11."
