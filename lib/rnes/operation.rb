require 'rnes/operation/records'

module Rnes
  class Operation
    NAMES_ALLOWING_IMMEDIATE_ADDRESSING_MODE = %i[
      ADC
      AND
      CMP
      CPX
      CPY
      EOR
      LDA
      LDX
      LDY
      ORA
      SBC
    ].freeze

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

    # @return [Boolean]
    def allowing_immediate?
      NAMES_ALLOWING_IMMEDIATE_ADDRESSING_MODE.include?(name)
    end
  end
end
