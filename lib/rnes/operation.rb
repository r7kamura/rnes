require 'rnes/errors'
require 'rnes/operation/records'

module Rnes
  class Operation
    class << self
      # @param [Integer] operation_code
      # @return [Rnes::Operation]
      def build(operation_code)
        record = ::Rnes::Operation::RECORDS[operation_code]
        if record
          new(record)
        else
          raise ::Rnes::InvalidOperationCodeError, "Invalid operation code: #{operation_code}"
        end
      end
    end

    # @return [Symbol]
    attr_reader :addressing_mode

    # @return [Integer]
    attr_reader :cycle

    # @return [Symbol]
    attr_reader :full_name

    # @return [Symbol]
    attr_reader :name

    # @param [Symbol] addressing_mode
    # @param [Integer] cycle
    # @param [Symbol] full_name
    # @param [Symbol] name
    def initialize(addressing_mode:, cycle:, full_name:, name:)
      @addressing_mode = addressing_mode
      @cycle = cycle
      @full_name = full_name
      @name = name
    end

    # @return [Hash]
    def to_hash
      {
        addressing_mode: addressing_mode,
        cycle: cycle,
        full_name: full_name,
        name: name,
      }
    end
  end
end
