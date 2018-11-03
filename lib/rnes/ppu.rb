require 'rnes/errors'
require 'rnes/ppu_registers'
require 'rnes/ppu/colors'
require 'rnes/ram'

module Rnes
  class Ppu
    ADDRESS_TO_START_ATTRIBUTE_TABLE = 0x23C0

    ADDRESS_TO_START_NAME_TABLE = 0x2000

    BLOCK_HEIGHT = 16

    BLOCK_WIDTH = 16

    CYCLES_PER_LINE = 341

    PALETTE_BYTESIZE = 32

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
        ::Array.new(PALETTE_BYTESIZE).map do
          0
        end
      end

      private

      # @return [Integer]
      def visible_window_area
        VISIBLE_WINDOW_WIDTH * VISIBLE_WINDOW_HEIGHT
      end
    end

    # @note For debug use.
    # @param [Integer]
    # @return [Integer]
    attr_accessor :cycle

    # @note For debug use.
    # @param [Integer]
    # @return [Integer]
    attr_accessor :line

    # @param [Array<Array<Integer>>]
    attr_reader :image

    # @return [Rnes::PpuRegisters]
    attr_reader :registers

    # @param [Rnes::PpuBus] bus
    def initialize(bus:)
      @bus = bus
      @cycle = 0
      @image = self.class.generate_empty_image
      @line = 0
      @mini_palette_ids_byte = 0x0
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

    # @note Drawing next 8 pixels per 8 cycles.
    def draw
      if x_in_tile.zero?
        @sprite_index = read_sprite_index_from_name_table
        @mini_palette_ids_byte = read_mini_palette_ids_byte
        @sprite_line_low_byte = read_sprite_line_low_byte
        @sprite_line_high_byte = read_sprite_line_high_byte
        update_eight_pixels
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

    # @return [Integer] Which 4-color-palette to use (0-3)
    def mini_palette_id
      (@mini_palette_ids_byte >> (block_position * 2)) & 0b11
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

    # @return [Integer] 4-color-palette IDs of 4 blocks, as 8 bit data.
    def read_mini_palette_ids_byte
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

    def render_image
      puts "\e[61A\e[128D"
      60.times do |y_of_character|
        128.times do |x_of_character|
          base = y_of_character * 4 * 256 + x_of_character * 2
          print(
            (
              (
                 (@image[base + 256 * 0 + 0].sum < 384 ? 0 : 1) |
                ((@image[base + 256 * 1 + 0].sum < 384 ? 0 : 1) << 1) |
                ((@image[base + 256 * 2 + 0].sum < 384 ? 0 : 1) << 2) |
                ((@image[base + 256 * 0 + 1].sum < 384 ? 0 : 1) << 3) |
                ((@image[base + 256 * 1 + 1].sum < 384 ? 0 : 1) << 4) |
                ((@image[base + 256 * 2 + 1].sum < 384 ? 0 : 1) << 5) |
                ((@image[base + 256 * 3 + 0].sum < 384 ? 0 : 1) << 6) |
                ((@image[base + 256 * 3 + 1].sum < 384 ? 0 : 1) << 7)
               ) + 0x2800
            ).chr('UTF-8')
          )
        end
        puts
      end
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
      mini_palette_id_memo = mini_palette_id
      8.times do |x_in_sprite|
        index_in_sprite_line_byte = 7 - x_in_sprite
        color_id = @palette[
          @sprite_line_low_byte[index_in_sprite_line_byte] | @sprite_line_high_byte[index_in_sprite_line_byte] << 1 | mini_palette_id_memo << 2
        ]
        image_index = VISIBLE_WINDOW_WIDTH * y + x + x_in_sprite
        @image[image_index] = ::Rnes::Ppu::COLORS[color_id]
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
        @bus.write(@video_ram_address, value)
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
