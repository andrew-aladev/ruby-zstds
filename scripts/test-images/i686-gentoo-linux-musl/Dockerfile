ARG FROM_IMAGE
FROM $FROM_IMAGE

COPY root /
RUN cp -R /mnt/common-root/* /
# TODO https://bugs.gentoo.org/835038
RUN rm /var/db/repos/gentoo/dev-lang/ruby/files/3.1/900-musl-*.patch && \
  sed -i 's/use elibc_musl/[false]/' /var/db/repos/gentoo/dev-lang/ruby/ruby-3.1.1.ebuild && \
  ebuild /var/db/repos/gentoo/dev-lang/ruby/ruby-3.1.1.ebuild manifest
RUN build.sh -v \
  dev-vcs/git app-arch/zstd \
  dev-lang/ruby:2.6 dev-lang/ruby:2.7 dev-lang/ruby:3.0 dev-lang/ruby:3.1 \
  virtual/rubygems && \
  cleanup.sh
