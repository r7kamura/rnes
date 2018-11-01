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

    # @note program counter
    # @param [Integer]
    # @return [Integer]
    attr_accessor :pc

    def initialize
      @a = 0x00
      @p = 0b00000000
      @pc = 0x0000
      @sp = 0x0000
      @x = 0x00
      @y = 0x00
    end

    # @return [Boolean]
    def has_break_bit?
      @p[BREAK_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_carry_bit?
      @p[CARRY_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_decimal_bit?
      @p[DECIMAL_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_interrupt_bit?
      @p[INTERRUPT_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_negative_bit?
      @p[NEGATIVE_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_overflow_bit?
      @p[OVERFLOW_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_reserved_bit?
      @p[RESERVED_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_zero_bit?
      @p[ZERO_BIT_INDEX] == 1
    end

    def reset
      @a = 0x00
      @p = 0b00110100
      @pc = 0x0000
      @sp = 0x1FD
      @x = 0x00
      @y = 0x00
    end
  end
end
