require 'rnes/ppu_registers'
require 'rnes/ram'

module Rnes
  class Ppu
    CYCLES_PER_LINE = 341

    LINE_TO_FINISH_V_BLANK = 261

    LINE_TO_START_V_BLANK = 240

    NAME_TABLE_START_ADDRESS = 0x2000

    PALETTE_SIZE = 256

    TILE_HEIGHT = 8

    TILE_WIDTH = 8

    VISIBLE_WINDOW_WIDTH = 256

    # @param [Rnes::PpuBus] bus
    def initialize(bus:)
      @bus = bus
      @colors = ::Array.new(VISIBLE_WINDOW_WIDTH * LINE_TO_START_V_BLANK).map do
        [
          0, # Red
          0, # Green
          0, # Blue
        ]
      end
      @cycle = 0
      @line = 0
      @palette = ::Array.new(PALETTE_SIZE).map do
        0
      end
      @registers = ::Rnes::PpuRegisters.new
      @sprite_ram = ::Rnes::Ram.new
      @tile_bitmap_high = 0
      @tile_bitmap_low = 0
      @video_ram = ::Rnes::Ram.new
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bus.read(address)
    end

    # @todo
    def tick
      if (0...LINE_TO_START_V_BLANK).cover?(@line)
        if (1..VISIBLE_WINDOW_WIDTH).cover?(@cycle)
          if x_in_tile.zero?
            draw_eight_pixels
          end
        end
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
      (attribute_table_byte >> attribute_shift) & 0b11
    end

    def draw_eight_pixels
      8.times do |i|
        tile_bitmap_index = 7 - i
        palette_index = @tile_bitmap_low[tile_bitmap_index] | @tile_bitmap_high[tile_bitmap_index] << 1 | attribute_value << 2
        rgb_index = @palette[palette_index]
        colors[VISIBLE_WINDOW_WIDTH * y + x + i] = [
          rgb_palette[rgb_index * 3 + 0],
          rgb_palette[rgb_index * 3 + 1],
          rgb_palette[rgb_index * 3 + 2],
        ]
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

    # @return [Integer]
    def tile_index
      y_of_tile * (VISIBLE_WINDOW_WIDTH / TILE_WIDTH) + x_of_tile
    end

    # @return [Integer]
    def x
      @cycle - 1
    end

    # @return [Integer]
    def x_in_tile
      x % TILE_WIDTH
    end

    # @return [Integer]
    def x_of_tile
      Math.floor(x / TILE_WIDTH)
    end

    # @return [Integer]
    def y
      @line
    end

    # @return [Integer]
    def y_in_tile
      y % TILE_HEIGHT
    end

    # @return [Integer]
    def y_of_tile
      Math.floor(y / TILE_HEIGHT)
    end
  end
end
