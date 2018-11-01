require 'rnes/cpu_bus'
require 'rnes/cpu_registers'
require 'rnes/operation'

module Rnes
  class Cpu
    # @return [Rnes::CpuRegisters]
    attr_reader :registers

    # @param [Rnes::CpuBus] bus
    def initialize(bus)
      @bus = bus
      @registers = ::Rnes::CpuRegisters.new
    end

    # @return [Rnes::Operation]
    def fetch_operation
      operation_code = fetch_operation_code
      operation = ::Rnes::Operation.build(operation_code)
    end

    # @return [Array<Rnes::OperationCode>]
    def operation_codes
      @operation_codes ||= []
    end

    def reset
      @registers.reset
      @registers.pc = read_word(0xFFFC)
    end

    private

    # @return [Integer]
    def fetch_operation_code
      address = @registers.pc
      operation_code = read(address)
      @registers.pc += 1
      operation_code
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bus.read(address)
    end

    # Read lower-byte and upper-byte, then return them as a word (2 bytes data).
    # @param [Integer] address
    # @return [Integer]
    def read_word(address)
      read(address) | read(address + 1) << 8
    end
  end
end
