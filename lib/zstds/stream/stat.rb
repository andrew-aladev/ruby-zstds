# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "forwardable"

module ZSTDS
  module Stream
    # ZSTDS::Stream::Stat class.
    class Stat
      # Libraries like minitar tries to access stat to know whether stream is seekable.
      # We need to mark stream as not directory, file, etc, because it is not seekable.

      # User can use disabled delegates using :io reader.

      extend ::Forwardable

      METHODS_RETURNING_FALSE = %i[
        blockdev?
        chardev?
        directory?
        executable?
        executable_real?
        file?
        grpowned?
        owned?
        pipe?
        setgid?
        setuid?
        socket?
        sticky?
        symlink?
        zero?
      ]
      .freeze

      DELEGATES = %i[
        <=>
        atime
        birthtime
        blksize
        blocks
        ctime
        dev
        dev_major
        dev_minor
        ftype
        gid
        ino
        inspect
        mode
        mtime
        nlink
        rdev
        rdev_major
        rdev_minor
        readable?
        readable_real?
        size
        size?
        uid
        world_readable?
        world_writable?
        writable?
        writable_real?
      ]
      .freeze

      def initialize(stat)
        @stat = stat
      end

      METHODS_RETURNING_FALSE.each do |method_name|
        define_method(method_name) { false }
      end

      def_delegators :@stat, *DELEGATES
    end
  end
end
