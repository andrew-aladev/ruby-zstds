ARG FROM_IMAGE=test_i686-gentoo-linux-musl
FROM $FROM_IMAGE

COPY root /
COPY attached-common-root /
RUN build.sh -v \
  dev-vcs/git app-arch/zstd \
  dev-lang/ruby:2.7 virtual/rubygems
