module Rnes
  class PpuRegisters
    STATUS_IN_V_BLANK_BIT_INDEX = 7
    STATUS_SPRITE_HIT_BIT_INDEX = 6

    # @param [Integer]
    # @return [Integer]
    attr_accessor :control1

    # @param [Integer]
    # @return [Integer]
    attr_accessor :control2

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
      @control1 = 0x0
      @control2 = 0x0
      @scroll_x = 0x0
      @scroll_y = 0x0
      @status = 0x0
    end

    # @return [Boolean]
    def background_enabled?
      @control2[3] == 1
    end

    # @return [Boolean]
    def has_background_bank_bit?
      @control1[4] == 1
    end

    # @return [Boolean]
    def has_in_v_blank_bit?
      @status[STATUS_IN_V_BLANK_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_large_video_ram_address_offset_bit?
      @control1[4] == 1
    end

    # @return [Boolean]
    def has_sprite_hit_bit?
      @status[STATUS_SPRITE_HIT_BIT_INDEX] == 1
    end

    # @return [Boolean]
    def has_sprite_bank_bit?
      @control1[3] == 1
    end

    # @return [Boolean]
    def has_v_blank_irq_enabled_bit?
      @control1[7] == 1
    end

    # @param [Boolean] boolean
    def in_v_blank=(boolean)
      toggle_status_bit(STATUS_IN_V_BLANK_BIT_INDEX, boolean)
    end

    # Name table id (address)
    # +------------+------------|
    # | 0 (0x2000) | 1 (0x2400) |
    # +------------+------------|
    # | 2 (0x2800) | 3 (0x2C00) |
    # +------------+------------|
    # @return [Integer] An integer from 0 to 3.
    def name_table_id
      @status & 0b11
    end

    def set_in_v_blank_bit
      @status |= (1 << STATUS_IN_V_BLANK_BIT_INDEX)
    end

    # @return [Boolean]
    def sprite_enabled?
      @control2[4] == 1
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
