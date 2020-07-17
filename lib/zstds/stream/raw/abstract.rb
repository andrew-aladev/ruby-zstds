# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "zstds_ext"

require_relative "../../error"
require_relative "../../validation"

module ZSTDS
  module Stream
    module Raw
      class Abstract
        def initialize(native_stream)
          @native_stream = native_stream
          @is_closed     = false
        end

        # -- write --

        def flush(&writer)
          write_result(&writer)

          nil
        end

        protected def more_destination(&writer)
          result_bytesize = write_result(&writer)
          raise NotEnoughDestinationError, "not enough destination" if result_bytesize.zero?
        end

        protected def write_result(&_writer)
          result = @native_stream.read_result
          yield result

          result.bytesize
        end

        # -- close --

        protected def do_not_use_after_close
          raise UsedAfterCloseError, "used after close" if closed?
        end

        def close(&writer)
          write_result(&writer)

          @native_stream.close
          @is_closed = true

          nil
        end

        def closed?
          @is_closed
        end
      end
    end
  end
end
