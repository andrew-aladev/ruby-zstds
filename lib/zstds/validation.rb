# Ruby bindings for zstd library.
# Copyright (c) 2019 AUTHORS, MIT License.

require "adsp/validation"

module ZSTDS
  # ZSTDS::Validation class.
  class Validation < ADSP::Validation
    def self.validate_bool(value)
      raise ValidateError, "invalid bool" unless value.is_a?(::TrueClass) || value.is_a?(::FalseClass)
    end

    def self.validate_integer(value)
      raise ValidateError, "invalid integer" unless value.is_a? ::Integer
    end
  end
end
