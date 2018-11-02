require 'rnes/errors'
require 'rnes/ppu_registers'
require 'rnes/ppu/rgb_palette'
require 'rnes/ram'

module Rnes
  class Ppu
    ADDRESS_TO_START_ATTRIBUTE_TABLE = 0x23C0

    ADDRESS_TO_START_NAME_TABLE = 0x2000

    BLOCK_HEIGHT = 16

    BLOCK_WIDTH = 16

    CYCLES_PER_LINE = 341

    PALETTE_SIZE = 256

    SPRITE_HEIGHT = 8

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
      @palette_indices_byte = 0x0
      @bus = bus
      @cycle = 0
      @image = self.class.generate_empty_image
      @line = 0
      @palette = self.class.generate_empty_palette
      @registers = ::Rnes::PpuRegisters.new
      @sprite_line_high_byte = 0x0
      @sprite_line_low_byte = 0x0
      @sprite_ram = ::Rnes::Ram.new
      @sprite_ram_address = 0x00
      @video_ram_address = 0x0000
      @writing_video_ram_address = false
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      case address
      when 0x0002
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
      when 0x0000
        registers.control1 = value
      when 0x0001
        registers.control2 = value
      when 0x0003
        write_sprite_ram_address(value)
      when 0x0004
        write_to_sprite_ram(value)
      when 0x0005
        # TODO: scroll register
      when 0x0006
        write_video_ram_address(value)
      when 0x0007
        write_to_video_ram(value)
      else
        raise ::Rnes::Errors::UnknownPpuAddressError, "Unknown address: #{address}"
      end
    end

    private

    # 0b11
    #   |`- horizontal (1: right)
    #   `-- vertical   (1: bottom)
    # @return [Integer]
    def block_position
      shift = 0
      shift |= 0b01 if drawing_right_block?
      shift |= 0b10 if drawing_bottom_block?
      shift
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
        @sprite_index = read_sprite_index_from_name_table
      when 3
        @palette_indices_byte = read_palette_indices_byte
      when 5
        @sprite_line_low_byte = read_sprite_line_low_byte
      when 7
        @sprite_line_high_byte = read_sprite_line_high_byte
      end
    end

    # @return [Boolean]
    def drawing_bottom_block?
      (y % BLOCK_HEIGHT).odd?
    end

    # @return [Boolean]
    def drawing_right_block?
      (x % BLOCK_WIDTH).odd?
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

    # @return [Integer]
    def palette_index
      (@palette_indices_byte >> (block_position * 2)) & 0b11
    end

    # @note 2 bit index for which one to use from 4 palettes, for each 4 block = 8 bit = 1 byte.
    # @return [Integer]
    def read_palette_indices_byte
      @bus.read(ADDRESS_TO_START_ATTRIBUTE_TABLE + tile_index)
    end

    # @note A sprite index represents which sprite should be drawn to this tile.
    # @return [Integer]
    def read_sprite_index_from_name_table
      @bus.read(ADDRESS_TO_START_NAME_TABLE + tile_index)
    end

    # @return [Integer]
    def read_sprite_line_high_byte
      @bus.read(sprite_line_high_byte_address)
    end

    # @return [Integer]
    def read_sprite_line_low_byte
      @bus.read(sprite_line_low_byte_address)
    end

    # @todo
    def render_image
    end

    def set_v_blank
      registers.toggle_in_v_blank_bit(true)
    end

    # @return [Integer]
    def sprite_line_high_byte_address
      sprite_line_low_byte_address + 8
    end

    # @return [Integer]
    def sprite_line_low_byte_address
      @sprite_index * SPRITE_HEIGHT * 2 + y_in_tile
    end

    # @return [Integer]
    def tile_index
      y_of_tile * (VISIBLE_WINDOW_WIDTH / TILE_WIDTH) + x_of_tile
    end

    def update_eight_pixels
      current_palette_index = palette_index
      8.times do |x_in_sprite|
        index_in_sprite_line_byte = 7 - x_in_sprite
        palette_index = @sprite_line_low_byte[index_in_sprite_line_byte] | @sprite_line_high_byte[index_in_sprite_line_byte] << 1 | current_palette_index << 2
        rgb_index = @palette[palette_index]
        @image[VISIBLE_WINDOW_WIDTH * y + x + x_in_sprite] = [
          ::Rnes::Ppu::RGB_PALETTE[rgb_index * 3 + 0],
          ::Rnes::Ppu::RGB_PALETTE[rgb_index * 3 + 1],
          ::Rnes::Ppu::RGB_PALETTE[rgb_index * 3 + 2],
        ]
      end
    end

    # @return [Integer]
    def video_ram_address_offset
      if registers.has_large_video_ram_address_offset_bit?
        32
      else
        1
      end
    end

    # @param [Integer] address
    def write_sprite_ram_address(address)
      @sprite_ram_address = address
    end

    # @param [Integer] value
    def write_to_sprite_ram(value)
      @sprite_ram.write(@sprite_ram_address, value)
      @sprite_ram_address += 1
    end

    # @param [Integer] address
    def write_video_ram_address(address)
      if @writing_video_ram_address
        @video_ram_address |= address
      else
        @video_ram_address = address << 8
      end
      @writing_video_ram_address = !@writing_video_ram_address
    end

    # @param [Integer] value
    def write_to_video_ram(value)
      case @video_ram_address
      when 0x0000..0x1FFF
        # TODO: write to character RAM
      when 0x3F00..0x3FFF
        @palette[@video_ram_address - 0x3F00] = value
      else
        @video_ram.write(@video_ram_address, value)
      end
      @video_ram_address += video_ram_address_offset
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
