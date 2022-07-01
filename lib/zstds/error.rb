# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp"

module ZSTDS
  class BaseError < ::StandardError; end

  class AllocateError < BaseError; end

  class NotEnoughSourceBufferError       < BaseError; end
  class NotEnoughDestinationBufferError  < BaseError; end
  class DecompressorCorruptedSourceError < BaseError; end
  class CorruptedDictionaryError         < BaseError; end

  class AccessIOError < BaseError; end
  class ReadIOError   < BaseError; end
  class WriteIOError  < BaseError; end

  ValidateError = ADSP::ValidateError

  NotEnoughDestinationError = ADSP::NotEnoughDestinationError
  UsedAfterCloseError       = ADSP::UsedAfterCloseError

  NotImplementedError = ADSP::NotImplementedError
  UnexpectedError     = ADSP::UnexpectedError
end
