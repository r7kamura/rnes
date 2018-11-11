module Rnes
  class PpuRegisters
    STATUS_IN_V_BLANK_BIT_INDEX = 7
    STATUS_SPRITE_HIT_BIT_INDEX = 6
    STATUS_OVERFLOW_BIT_INDEX = 5

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

    # @return [Boolean]
    def background_pattern_table_address_banked?
      @control[4] == 1
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
    def color_blue_emphasized?
      @mask[7] == 1
    end

    # @return [Boolean]
    def color_green_emphasized?
      @mask[6] == 1
    end

    # @return [Boolean]
    def color_red_emphasized?
      @mask[5] == 1
    end

    # @return [Boolean]
    def color_greyscaled?
      @mask[0] == 1
    end

    # @return [Boolean]
    def has_v_blank_irq_enabled_bit?
      @control[7] == 1
    end

    # @return [Boolean]
    def horizontal_increment?
      @control[2] == 1
    end

    # @return [Boolean]
    def in_v_blank?
      @status[STATUS_IN_V_BLANK_BIT_INDEX] == 1
    end

    # @param [Boolean] boolean
    def in_v_blank=(boolean)
      toggle_status_bit(STATUS_IN_V_BLANK_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def leftmost_background_shown?
      @mask[1] == 1
    end

    # @return [Boolean]
    def leftmost_sprite_shown?
      @mask[2] == 1
    end

    # @param [Boolean] boolean
    def overflow=(boolean)
      toggle_status_bit(STATUS_OVERFLOW_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def sprite_enabled?
      @mask[4] == 1
    end

    # @return [Boolean]
    def sprite_hit?
      @status[STATUS_SPRITE_HIT_BIT_INDEX] == STATUS_SPRITE_HIT_BIT_INDEX
    end

    # @param [Boolean] boolean
    def sprite_hit=(boolean)
      toggle_status_bit(STATUS_SPRITE_HIT_BIT_INDEX, boolean)
    end

    # @return [Boolean]
    def sprite_pattern_table_address_banked?
      @control[3] == 1
    end

    # @return [Boolean]
    def sprite_size_doubled?
      @control[4] == 1
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
