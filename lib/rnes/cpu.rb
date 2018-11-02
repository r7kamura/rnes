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
      when :LDA
        execute_operation_lda(operation)
      else
        raise ::Rnes::Errors::UnknownOperationError, "Unknown operation: #{operation.name}"
      end
    end

    # @param [Rnes::Operation] operation
    def execute_operation_brk(_operation)
      registers.set_break_bit
      stack_program_counter
      stack_status
      unless registers.has_interrupt_bit?
        registers.set_interrupt_bit
        registers.pc = read_word(0xFFFE)
      end
      registers.pc -= 1
    end

    # @todo negative check
    # @todo zero check
    # @param [Rnes::Operation] operation
    def execute_operation_lda(operation)
      value = fetch_value_by_addressing_mode(operation.addressing_mode)
      registers.a = value
    end

    # @return [Integer]
    def fetch
      address = @registers.pc
      value = read(address)
      @registers.pc += 1
      value
    end

    # @return [Rnes::Operation]
    def fetch_operation
      operation_code = fetch
      ::Rnes::Operation.build(operation_code)
    end

    # @param [Symbol] addressing_mode
    # @return [Integer]
    def fetch_value_by_addressing_mode(addressing_mode)
      case addressing_mode
      when :absolute
        fetch_value_by_addressing_mode_absolute
      when :absolute_x
        fetch_value_by_addressing_mode_absolute_x
      when :absolute_y
        fetch_value_by_addressing_mode_absolute_y
      when :accumulator
        fetch_value_by_addressing_mode_accumulator
      when :immediate
        fetch_value_by_addressing_mode_immediate
      when :implied
        fetch_value_by_addressing_mode_implied
      when :indirect_absolute
        fetch_value_by_addressing_mode_indirect_absolute
      when :post_indexed_indirect
        fetch_value_by_addressing_mode_post_indexed_indirect
      when :pre_indexed_indirect
        fetch_value_by_addressing_mode_pre_indexed_indirect
      when :relative
        fetch_value_by_addressing_mode_relative
      when :zero_page
        fetch_value_by_addressing_mode_zero_page
      when :zero_page_x
        fetch_value_by_addressing_mode_zero_page_x
      when :zero_page_y
        fetch_value_by_addressing_mode_zero_page_y
      else
        raise ::Rnes::Errors::UnknownAddressingModeError, "Unknown addressing mode: #{addressing_mode}"
      end
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_immediate
      fetch
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page
      address = fetch
      read(address)
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
