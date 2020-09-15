ARG FROM_IMAGE=test_x86_64-unknown-linux-gnu
FROM $FROM_IMAGE

COPY root /
COPY attached-common-root /
RUN build.sh -v \
  dev-vcs/git app-arch/zstd \
  dev-lang/ruby:2.7 virtual/rubygems
