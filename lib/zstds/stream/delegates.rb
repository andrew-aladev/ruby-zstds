# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "forwardable"

module ZSTDS
  module Stream
    # ZSTDS::Stream::Delegates module.
    module Delegates
      DELEGATES = %i[
        autoclose=
        autoclose?
        binmode
        binmode?
        close_on_exec=
        close_on_exec?
        fcntl
        fdatasync
        fileno
        fsync
        ioctl
        isatty
        pid
        sync
        sync=
        to_i
        tty?
      ]
      .freeze

      def self.included(klass)
        klass.extend ::Forwardable
        klass.def_delegators :@io, *DELEGATES
      end
    end
  end
end
