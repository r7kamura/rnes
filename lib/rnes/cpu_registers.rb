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
    attr_accessor :accumulator

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

    # @param [Integer]
    # @return [Integer]
    attr_accessor :status

    def initialize
      @accumulator = 0x00
      @index_x = 0x00
      @index_y = 0x00
      @program_counter = 0x0000
      @stack_pointer = 0x0000
      @status = 0b00000000
    end

    # @return [Boolean]
    def break?
      @status[BREAK_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def break=(boolean)
      toggle_bit(BREAK_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def carry?
      @status[CARRY_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def carry=(boolean)
      toggle_bit(CARRY_BIT_INDEX, boolean)
    end

    # @return [Integer]
    def carry_bit
      @status[CARRY_BIT_INDEX]
    end

    # @return [Boolean]
    def decimal?
      @status[DECIMAL_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def decimal=(boolean)
      toggle_bit(DECIMAL_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def interrupt?
      @status[INTERRUPT_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def interrupt=(boolean)
      toggle_bit(INTERRUPT_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def negative?
      @status[NEGATIVE_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def negative=(boolean)
      toggle_bit(NEGATIVE_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def overflow?
      @status[OVERFLOW_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def reserved?
      @status[RESERVED_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def reserved=(boolean)
      toggle_bit(RESERVED_BIT_INDEX, boolean)
    end

    def reset
      @accumulator = 0x00
      @index_x = 0x00
      @index_y = 0x00
      @program_counter = 0x0000
      @stack_pointer = 0x1FD
      @status = 0b00110100
    end

    # @param [Boolean] boolean
    def overflow=(boolean)
      toggle_bit(OVERFLOW_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def zero?
      @status[ZERO_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def zero=(boolean)
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
