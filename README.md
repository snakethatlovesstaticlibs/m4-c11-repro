# m4 C dialect mismatch reproduction

This standalone Bazel repository builds GNU m4 from Bazel Central Registry using
the public [f0rmiga/gcc-toolchain](https://github.com/f0rmiga/gcc-toolchain).
It has no private dependencies and does not require an installed C/C++ compiler.

## Versions and toolchain selection

- Bazel: 9.3.0.
- m4: 1.4.21.bcr.6.
- rules_cc_autoconf: 0.26.0.
- rules_cc: 0.2.26.
- gcc_toolchain: 0.13.0, explicitly selecting GCC 15.2.0.
- Execution and target platform: Linux x86_64.

`MODULE.bazel` declares and registers the public GCC 15.2.0 toolchain.
`.bazelrc` disables system compiler detection. The toolchain downloads its pinned,
checksum-verified compiler and sysroot from public GitHub releases. It does not
override the compiler's default C dialect, which is GNU C23 for GCC 15.
The toolchain's explicit static libstdc++ linkage is enabled for the C++ probe
helpers, as required by this toolchain's documented C++ setup.

The toolchain binaries require a Linux x86_64 execution host. On macOS or Linux
ARM64, use the Docker instructions below; Docker must support amd64 emulation.

## Reproduce using Docker

The image installs Bazel and basic download utilities, but no system compiler.

```sh
docker build --platform linux/amd64 -t m4-c11-repro .
docker run --platform linux/amd64 --name m4-c11-repro m4-c11-repro bash reproduce.sh
```

The script succeeds only when the build fails with the expected `alignof` error
and the generated m4 config.h defines `HAVE_C_ALIGNASOF` to 1. The complete build
log is retained at `/repro/logs/failure.log` inside the container.

For the unwrapped failing build (exit code 1):

```sh
docker run --platform linux/amd64 m4-c11-repro
```

## Reproduce directly on Linux x86_64

With Bazel 9.3.0 (or Bazelisk) installed:

```sh
bash reproduce.sh
```

## Expected failure and explanation

```text
external/m4+/lib/mbsstr.c:55:25: error: implicit declaration of function 'alignof'; did you mean 'sa_alignof'?
external/m4+/lib/mbsstr.c:55:34: error: expected expression before 'mbchar_t'
```

The `rules_cc_autoconf` alignment check uses GCC's default C23 mode and detects
`alignof` as a keyword. This produces `#define HAVE_C_ALIGNASOF 1` in m4's
generated `config.h`, suppressing its fallback definition of `alignof`.

The BCR m4 overlay separately sets `-std=c11` on m4's C compilation targets.
The resulting C11 compilation uses configuration results obtained in C23 mode.

## Control: remove only the m4 C11 pin

Append the following to `MODULE.bazel`:

```python
single_version_override(
    module_name = "m4",
    version = "1.4.21.bcr.6",
    patch_strip = 1,
    patches = ["//patches:m4-use-toolchain-default.patch"],
)
```

Then rerun `bazel build //:m4` on Linux x86_64, or rebuild the Docker image and
run its default command. The included patch only removes `-std=c11` from the GCC
and Clang branches of `M4_COPTS`, so compilation uses the same default dialect as
the feature probes. Do not run `reproduce.sh` for this control: it expects failure.

## Validation

See `evidence.md` for the environments and observed results.
