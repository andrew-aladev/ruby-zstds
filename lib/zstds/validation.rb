# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/validation"

module ZSTDS
  # ZSTDS::Validation class.
  class Validation < ADSP::Validation
    # Raises error when +value+ is not boolean.
    def self.validate_bool(value)
      raise ValidateError, "invalid bool" unless value.is_a?(::TrueClass) || value.is_a?(::FalseClass)
    end

    # Raises error when +value+ is not integer.
    def self.validate_integer(value)
      raise ValidateError, "invalid integer" unless value.is_a? ::Integer
    end
  end
end
