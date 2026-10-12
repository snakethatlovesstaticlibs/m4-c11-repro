FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl patch unzip && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://releases.bazel.build/9.3.0/release/bazel-9.3.0-linux-x86_64 -o /usr/local/bin/bazel \
    && echo 'd302d22ed77ee5658b87857249baa579db84300ecebe0a1e9a357b5b20f80eb8  /usr/local/bin/bazel' | sha256sum -c - \
    && chmod +x /usr/local/bin/bazel

WORKDIR /repro
COPY . /repro
CMD ["bazel", "build", "//:m4"]
