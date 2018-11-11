module Rnes
  class PpuRegisters
    STATUS_IN_V_BLANK_BIT_INDEX = 7
    STATUS_SPRITE_HIT_BIT_INDEX = 6

    # @param [Integer]
    # @return [Integer]
    attr_accessor :control

    # @param [Integer]
    # @return [Integer]
    attr_accessor :mask

    # @param [Integer]
    # @return [Integer]
    attr_accessor :scroll_x

    # @param [Integer]
    # @return [Integer]
    attr_accessor :scroll_y

    # @param [Integer]
    # @return [Integer]
    attr_accessor :status

    def initialize
      @control = 0x0
      @mask = 0x0
      @scroll_x = 0x0
      @scroll_y = 0x0
      @status = 0x0
    end

    # @return [Boolean]
    def background_enabled?
      @mask[3] == 1
    end

    # +------------+------------|
    # | 0 (0x2000) | 1 (0x2400) |
    # +------------+------------|
    # | 2 (0x2800) | 3 (0x2C00) |
    # +------------+------------|
    # @return [Integer] An integer from 0 to 3.
    def base_name_table_id
      @control & 0b11
    end

    # @return [Boolean]
    def has_background_bank_bit?
      @control[4] == 1
    end

    # @return [Boolean]
    def has_in_v_blank_bit?
      @status[STATUS_IN_V_BLANK_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_sprite_hit_bit?
      @status[STATUS_SPRITE_HIT_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_sprite_bank_bit?
      @control[3] == 1
    end

    # @return [Boolean]
    def has_v_blank_irq_enabled_bit?
      @control[7] == 1
    end

    # @return [Boolean]
    def horizontal_increment?
      @control[4] == 1
    end

    # @param [Boolean] boolean
    def in_v_blank=(boolean)
      toggle_status_bit(STATUS_IN_V_BLANK_BIT_INDEX, boolean)
    end

    def set_in_v_blank_bit
      @status |= (1 << STATUS_IN_V_BLANK_BIT_INDEX)
    end

    # @return [Boolean]
    def sprite_enabled?
      @mask[4] == 1
    end

    # @param [Boolean] boolean
    def sprite_hit=(boolean)
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
