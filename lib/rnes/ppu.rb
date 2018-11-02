require 'rnes/errors'
require 'rnes/ppu_registers'
require 'rnes/ppu/rgb_palette'
require 'rnes/ram'

module Rnes
  class Ppu
    ADDRESS_TO_START_ATTRIBUTE_TABLE = 0x23C0

    ADDRESS_TO_START_NAME_TABLE = 0x2000

    CYCLES_PER_LINE = 341

    PALETTE_SIZE = 256

    TILE_HEIGHT = 8

    TILE_WIDTH = 8

    V_BLANK_HEIGHT = 21

    VISIBLE_WINDOW_HEIGHT = 240

    VISIBLE_WINDOW_WIDTH = 256

    class << self
      # @return [Array<Array<Integer>>]
      def generate_empty_image
        ::Array.new(visible_window_area).map do
          [
            0, # Red
            0, # Green
            0, # Blue
          ]
        end
      end

      # @return [Array<Integer>]
      def generate_empty_palette
        ::Array.new(PALETTE_SIZE).map do
          0
        end
      end

      private

      # @return [Integer]
      def visible_window_area
        VISIBLE_WINDOW_WIDTH * VISIBLE_WINDOW_HEIGHT
      end
    end

    # @param [Integer]
    # @return [Integer]
    attr_accessor :cycle

    # @param [Integer]
    # @return [Integer]
    attr_accessor :line

    # @return [Rnes::PpuRegisters]
    attr_reader :registers

    # @param [Rnes::PpuBus] bus
    def initialize(bus:)
      @attribute_table_byte = 0x0
      @bus = bus
      @cycle = 0
      @image = self.class.generate_empty_image
      @line = 0
      @palette = self.class.generate_empty_palette
      @registers = ::Rnes::PpuRegisters.new
      @sprite_ram = ::Rnes::Ram.new
      @tile_bitmap_high_byte = 0x0
      @tile_bitmap_low_byte = 0x0
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      case address
      when 0x2002
        registers.status
      else
        raise ::Rnes::Errors::UnknownPpuAddressError, "Unknown address: #{address}"
      end
    end

    # @todo
    def tick
      if on_visible_cycle?
        draw
      end
      if on_right_end_cycle?
        self.cycle = 0
        if on_bottom_end_line?
          self.line = 0
          clear_nmi
          clear_sprite_hit
          clear_v_blank
          render_image
        else
          self.line += 1
          if on_line_to_start_v_blank?
            set_v_blank
          end
        end
      else
        self.cycle += 1
      end
    end

    # @param [Integer] address
    # @param [Integer] value
    # @return [Integer]
    def write(address, value)
      case address
      when 0x2000
        registers.control1 = value
      when 0x2001
        registers.control2 = value
      when 0x2003
        # TODO sprite address register
      when 0x2004
        # TODO sprite address register
      when 0x2005
        # TODO scroll register
      when 0x2006
        # TODO VRAM address register
      when 0x2007
        # TODO VRAM access register
      when 0x4014
        # TODO sprite DMA register
      else
        raise ::Rnes::Errors::UnknownPpuAddressError, "Unknown address: #{address}"
      end
    end

    private

    # @return [Integer]
    def attribute_shift
      shift = 0
      shift += 2 unless drawing_left_tile?
      shift += 4 unless drawing_top_tile?
      shift
    end

    # @return [Integer]
    def attribute_value
      (@attribute_table_byte >> attribute_shift) & 0b11
    end

    # @todo
    def clear_nmi
    end

    def clear_sprite_hit
      registers.toggle_sprite_hit_bit(false)
    end

    def clear_v_blank
      registers.toggle_in_v_blank_bit(false)
    end

    def draw
      case x_in_tile
      when 0
        update_eight_pixels
      when 1
        @pattern_index = @bus.read(ADDRESS_TO_START_NAME_TABLE + tile_index)
      when 3
        @attribute_table_byte = @bus.read(ADDRESS_TO_START_ATTRIBUTE_TABLE + tile_index)
      when 5
        @tile_bitmap_low_byte = @bus.read(@pattern_index * 16 + y_in_tile)
      when 7
        @tile_bitmap_high_byte = @bus.read(@pattern_index * 16 + y_in_tile + 8)
      end
    end

    # @return [Boolean]
    def drawing_left_tile?
      (x % 16).even?
    end

    # @return [Boolean]
    def drawing_top_tile?
      (y % 16).even?
    end

    # @return [Boolean]
    def on_bottom_end_line?
      line == VISIBLE_WINDOW_HEIGHT + V_BLANK_HEIGHT
    end

    # @return [Boolean]
    def on_line_to_start_v_blank?
      line == VISIBLE_WINDOW_HEIGHT
    end

    # @return [Boolean]
    def on_right_end_cycle?
      cycle == CYCLES_PER_LINE - 1
    end

    # @return [Boolean]
    def on_visible_cycle?
      (0...VISIBLE_WINDOW_WIDTH).cover?(x) && (0...VISIBLE_WINDOW_HEIGHT).cover?(y)
    end

    # @todo
    def render_image
    end

    def set_v_blank
      registers.toggle_in_v_blank_bit(true)
    end

    # @return [Integer]
    def tile_index
      y_of_tile * (VISIBLE_WINDOW_WIDTH / TILE_WIDTH) + x_of_tile
    end

    def update_eight_pixels
      8.times do |i|
        tile_bitmap_index = 7 - i
        palette_index = @tile_bitmap_low_byte[tile_bitmap_index] | @tile_bitmap_high_byte[tile_bitmap_index] << 1 | attribute_value << 2
        rgb_index = @palette[palette_index]
        @image[VISIBLE_WINDOW_WIDTH * y + x + i] = [
          ::Rnes::Ppu::RGB_PALETTE[rgb_index * 3 + 0],
          ::Rnes::Ppu::RGB_PALETTE[rgb_index * 3 + 1],
          ::Rnes::Ppu::RGB_PALETTE[rgb_index * 3 + 2],
        ]
      end
    end

    # @return [Integer]
    def x
      cycle - 1
    end

    # @return [Integer]
    def x_in_tile
      x % TILE_WIDTH
    end

    # @return [Integer]
    def x_of_tile
      x / TILE_WIDTH
    end

    # @return [Integer]
    def y
      line
    end

    # @return [Integer]
    def y_in_tile
      y % TILE_HEIGHT
    end

    # @return [Integer]
    def y_of_tile
      y / TILE_HEIGHT
    end
  end
end
