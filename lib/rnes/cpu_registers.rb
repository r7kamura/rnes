module Rnes
  class CpuRegisters
    CARRY_BIT_INDEX = 0
    ZERO_BIT_INDEX = 1
    INTERRUPT_BIT_INDEX = 2
    DECIMAL_BIT_INDEX = 3
    BREAK_BIT_INDEX = 4
    RESERVED_BIT_INDEX = 5
    OVERFLOW_BIT_INDEX = 6
    NEGATIVE_BIT_INDEX = 7

    # @param [Integer]
    # @return [Integer]
    attr_accessor :accumlator

    # @param [Integer]
    # @return [Integer]
    attr_accessor :index_x

    # @param [Integer]
    # @return [Integer]
    attr_accessor :index_y

    # @param [Integer]
    # @return [Integer]
    attr_accessor :program_counter

    # @param [Integer]
    # @return [Integer]
    attr_accessor :stack_pointer

    # @return [Integer]
    attr_reader :status

    def initialize
      @accumlator = 0x00
      @index_x = 0x00
      @index_y = 0x00
      @program_counter = 0x0000
      @stack_pointer = 0x0000
      @status = 0b00000000
    end

    # @return [Integer]
    def carry_bit
      @status[CARRY_BIT_INDEX]
    end

    # @return [Boolean]
    def has_break_bit?
      @status[BREAK_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_carry_bit?
      @status[CARRY_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_decimal_bit?
      @status[DECIMAL_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_interrupt_bit?
      @status[INTERRUPT_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_negative_bit?
      @status[NEGATIVE_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_overflow_bit?
      @status[OVERFLOW_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_reserved_bit?
      @status[RESERVED_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_zero_bit?
      @status[ZERO_BIT_INDEX] == 1
    end

    def reset
      @accumlator = 0x00
      @index_x = 0x00
      @index_y = 0x00
      @program_counter = 0x0000
      @stack_pointer = 0x1FD
      @status = 0b00110100
    end

    # @param [Boolean] boolean
    def toggle_break_bit(boolean)
      toggle_bit(BREAK_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_carry_bit(boolean)
      toggle_bit(CARRY_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_decimal_bit(boolean)
      toggle_bit(DECIMAL_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_interrupt_bit(boolean)
      toggle_bit(INTERRUPT_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_negative_bit(boolean)
      toggle_bit(NEGATIVE_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_overflow_bit(boolean)
      toggle_bit(OVERFLOW_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_reserved_bit(boolean)
      toggle_bit(RESERVED_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_zero_bit(boolean)
      toggle_bit(ZERO_BIT_INDEX, boolean)
    end

    private

    # @param [Integer] index
    # @param [Boolean] boolean
    def toggle_bit(index, boolean)
      if boolean
        @status |= 1 << index
      else
        @status &= ~(1 << index)
      end
    end
  end
end
