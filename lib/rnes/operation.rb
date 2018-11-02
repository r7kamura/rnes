require 'rnes/operation/records'

module Rnes
  class Operation
    class << self
      # @param [Integer] operation_code
      # @return [Rnes::Operation]
      def build(operation_code)
        record = ::Rnes::Operation::RECORDS[operation_code]
        new(record)
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
  end
end
