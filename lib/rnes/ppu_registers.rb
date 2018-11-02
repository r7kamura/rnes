module Rnes
  class PpuRegisters
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
      @status[7] == 1
    end

    # @return [Boolean]
    def has_sprite_enabled_bit?
      @control2[4] == 1
    end

    # @return [Boolean]
    def has_sprite_hit_bit?
      @status[5] == 1
    end

    # @return [Boolean]
    def has_v_blank_irq_enabled_bit?
      @control1[6] == 1
    end
  end
end
