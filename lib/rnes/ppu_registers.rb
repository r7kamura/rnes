module Rnes
  class PpuRegisters
    STATUS_IN_V_BLANK_BIT_INDEX = 7
    STATUS_SPRITE_HIT_BIT_INDEX = 5

    def initialize
      @control1 = 0x0
      @control2 = 0x0
      @status = 0x0
    end

    # @return [Boolean]
    def has_background_enabled_bit?
      @control2[3] == 1
    end

    # @return [Boolean]
    def has_in_v_blank_bit?
      @status[STATUS_IN_V_BLANK_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_sprite_enabled_bit?
      @control2[4] == 1
    end

    # @return [Boolean]
    def has_sprite_hit_bit?
      @status[STATUS_SPRITE_HIT_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_v_blank_irq_enabled_bit?
      @control1[6] == 1
    end

    # @param [Boolean] boolean
    def toggle_in_v_blank_bit(boolean)
      toggle_status_bit(STATUS_IN_V_BLANK_BIT_INDEX, boolean)
    end

    # @param [Boolean] boolean
    def toggle_sprite_hit_bit(boolean)
      toggle_status_bit(STATUS_SPRITE_HIT_BIT_INDEX, boolean)
    end

    private

    # @param [Integer] index
    # @param [Boolean] boolean
    def toggle_status_bit(index, boolean)
      if boolean
        @status |= 1 << index
      else
        @status &= ~(1 << index)
      end
    end
  end
end
