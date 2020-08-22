ARG FROM_IMAGE=test_aarch64-gentoo-linux-musl
FROM $FROM_IMAGE

COPY root/ /
RUN build.sh -v \
  dev-vcs/git app-arch/zstd \
  dev-lang/ruby:2.7 virtual/rubygems

ENTRYPOINT ["/home/entrypoint.sh"]
