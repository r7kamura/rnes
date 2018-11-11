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

    # @return [Integer]
    attr_accessor :sprite_ram_address

    # @return [Integer]
    attr_reader :scroll_x

    # @return [Integer]
    attr_reader :scroll_y

    # @return [Integer]
    attr_reader :video_ram_address

    # @param [Integer]
    attr_writer :status

    def initialize
      @control = 0x0
      @mask = 0x0
      @status = 0x0

      @scroll_x = 0x0
      @scroll_y = 0x0

      @sprite_ram_address = 0x00
      @video_ram_address = 0x0000

      @address_latch = false
      @scroll_latch = false
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

    # @param [Integer] offset
    def increment_video_ram_address(offset)
      @video_ram_address += offset
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

    # @param [Integer] value
    def scroll=(value)
      if @scroll_latch
        @scroll_y = value
      else
        @scroll_x = value
      end
      @scroll_latch = !@scroll_latch
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

    # @return [Integer]
    def status
      value = @status
      self.in_v_blank = false
      @address_latch = false
      @scroll_latch = false
      value
    end

    # @param [Integer] value
    def video_ram_address=(value)
      if @address_latch
        @video_ram_address |= value
      else
        @video_ram_address = value << 8
      end
      @address_latch = !@address_latch
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
