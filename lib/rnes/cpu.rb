require 'rnes/cpu_bus'
require 'rnes/cpu_registers'
require 'rnes/errors'
require 'rnes/operation'

module Rnes
  class Cpu
    # @return [Rnes::CpuRegisters]
    attr_reader :registers

    # @param [Rnes::CpuBus] bus
    def initialize(bus:)
      @bus = bus
      @registers = ::Rnes::CpuRegisters.new
    end

    def reset
      @registers.reset
      @registers.pc = read_word(0xFFFC)
    end

    def tick
      operation = fetch_operation
      execute_operation(operation)
    end

    private

    # @param [Rnes::Operation] operation
    def execute_operation(operation)
      case operation.name
      when :BRK
        execute_operation_brk(operation)
      else
        raise ::Rnes::Errors::UnknownOperationError.new
      end
    end

    # @param [Rnes::Operation] operation
    def execute_operation_brk(operation)
      registers.set_break_bit
      stack_program_counter
      stack_status
      unless registers.has_interrupt_bit?
        registers.set_interrupt_bit
        registers.pc = read_word(0xFFFE)
      end
      registers.pc -= 1
    end

    # @return [Rnes::Operation]
    def fetch_operation
      operation_code = fetch_operation_code
      ::Rnes::Operation.build(operation_code)
    end

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

    # @param [Integer] value
    def stack(value)
      write(registers.sp | 0x100, value)
      registers.sp -= 1
    end

    def stack_program_counter
      stack_word(registers.pc)
    end

    def stack_status
      stack(registers.p)
    end

    # @param [Integer] value
    def stack_word(value)
      stack(value >> 8)
      stack(value & 0xFF)
    end

    # @return [Integer]
    def unstack
      registers.sp += 1
      read(registers.sp & 0xFF | 0x100)
    end

    # @param [Integer] address
    # @param [Integer] value
    def write(address, value)
      @bus.write(address, value)
    end
  end
end
