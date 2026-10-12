# Verified results

Verified on 2026-10-12 using Bazel 9.3.0 in a Debian bookworm Linux x86_64
container, running under Docker amd64 emulation on an ARM64 macOS host.

The container has no installed system C/C++ compiler. Bazel selected the public
`gcc_toolchain` 0.13.0 distribution of GCC 15.2.0 declared in `MODULE.bazel`.
System compiler detection was disabled throughout both builds.

## Unmodified m4 overlay: failure

Command: `bazel build //:m4`.

Result: exit code 1; the compiler error matches the original CI failure.

```text
external/m4+/lib/mbsstr.c:55:25: error: implicit declaration of function 'alignof'; did you mean 'sa_alignof'?
external/m4+/lib/mbsstr.c:55:34: error: expected expression before 'mbchar_t'
```

The failing command invokes:

```text
external/gcc_toolchain++gcc_toolchains+gcc15_15_2_0/xbin/gcc
```

Its arguments include `-std=c11`.

The generated `bazel-bin/external/m4+/lib/config.h` contains:

```c
#define HAVE_C_ALIGNASOF 1
```

This confirms that feature detection enabled native alignment keywords even
though m4's actual compilation used C11.

## Control patch: success

Applied `patches/m4-use-toolchain-default.patch` via the `single_version_override`
shown in `README.md`. No compiler options were added to the probes or Bazel's
global configuration. The patch removes only the two `-std=c11` entries in
m4's `M4_COPTS` (GCC and Clang branches).

Command: `bazel build //:m4`.

Result: exit code 0.

```text
Target @@m4+//:m4 up-to-date:
  bazel-bin/external/m4+/m4
INFO: Build completed successfully, 270 total actions
```

Both runs used the same toolchain and other dependency versions.
