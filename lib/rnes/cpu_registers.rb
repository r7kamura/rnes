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

    # @note accumulator
    # @param [Integer]
    # @return [Integer]
    attr_accessor :a

    # @note program counter
    # @param [Integer]
    # @return [Integer]
    attr_accessor :pc

    # @note stack pointer
    # @param [Integer]
    # @return [Integer]
    attr_accessor :sp

    # @note status
    # @return [Integer]
    attr_reader :p

    # @note index X
    # @param [Integer]
    # @return [Integer]
    attr_accessor :x

    # @note index Y
    # @param [Integer]
    # @return [Integer]
    attr_accessor :y

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
        @p |= 1 << index
      else
        @p &= ~(1 << index)
      end
    end
  end
end
