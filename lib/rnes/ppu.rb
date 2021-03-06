require 'rnes/errors'
require 'rnes/image'
require 'rnes/ppu_registers'
require 'rnes/ppu/colors'
require 'rnes/ram'

module Rnes
  class Ppu
    ADDRESS_TO_FINISH_SPRITE_PALETTE_TABLE = 0x3F1F

    ADDRESS_TO_START_ATTRIBUTE_TABLE = 0x23C0

    ADDRESS_TO_START_NAME_TABLE = 0x2000

    ADDRESS_TO_START_BACKGROUND_PALETTE_TABLE = 0x3F00

    ADDRESS_TO_START_SPRITE_PALETTE_TABLE = 0x3F10

    BLOCK_HEIGHT = 16

    BLOCK_WIDTH = 16

    CYCLES_PER_LINE = 341

    PALETTE_ADDRESS_RANGE = (ADDRESS_TO_START_BACKGROUND_PALETTE_TABLE..ADDRESS_TO_FINISH_SPRITE_PALETTE_TABLE).freeze

    SPRITE_RAM_BYTESIZE = 2**8

    SPRITES_COUNT = 64

    TILE_HEIGHT = 8

    TILE_WIDTH = 8

    V_BLANK_HEIGHT = 21

    WINDOW_HEIGHT = 240

    WINDOW_WIDTH = 256

    ENCODED_ATTRIBUTES_HEIGHT = BLOCK_HEIGHT * 2

    ENCODED_ATTRIBUTES_WIDTH = BLOCK_WIDTH * 2

    ENCODED_ATTRIBUTES_COUNT_IN_HORIZONTAL_LINE = WINDOW_WIDTH / ENCODED_ATTRIBUTES_WIDTH

    ENCODED_ATTRIBUTES_COUNT_IN_VERTICAL_LINE = 256 / ENCODED_ATTRIBUTES_HEIGHT

    TILES_COUNT_IN_HORIZONTAL_LINE = WINDOW_WIDTH / TILE_WIDTH

    TILES_COUNT_IN_VERTICAL_LINE = WINDOW_HEIGHT / TILE_HEIGHT

    TILES_COUNT_IN_WINDOW = TILES_COUNT_IN_HORIZONTAL_LINE * TILES_COUNT_IN_VERTICAL_LINE

    # @note For debug use.
    # @param [Integer]
    # @return [Integer]
    attr_accessor :cycle

    # @note For debug use.
    # @param [Integer]
    # @return [Integer]
    attr_accessor :line

    # @note For debug use.
    # @return [Array<Rnes::Image>]
    attr_reader :image

    # @note For debug use.
    # @return [Rnes::PpuRegisters]
    attr_reader :registers

    # @param [Rnes::PpuBus] bus
    # @param [Rnes::InterruptLine] interrupt_line
    # @param [Rnes::TerminalRenderer] renderer
    def initialize(bus:, interrupt_line:, renderer:)
      @bus = bus
      @cycle = 0
      @image = ::Rnes::Image.new(height: WINDOW_HEIGHT, width: WINDOW_WIDTH)
      @interrupt_line = interrupt_line
      @line = 0
      @registers = ::Rnes::PpuRegisters.new
      @renderer = renderer
      @sprite_ram = ::Rnes::Ram.new(bytesize: SPRITE_RAM_BYTESIZE)
      @video_ram_reading_buffer = 0x00
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      case address
      when 0x0000
        @registers.control
      when 0x0001
        @registers.mask
      when 0x0002
        @registers.status
      when 0x0004
        read_from_sprite_ram(@registers.sprite_ram_address)
      when 0x0007
        read_from_video_ram_for_cpu
      else
        raise ::Rnes::Errors::InvalidPpuAddressError, address
      end
    end

    def step
      if on_visible_cycle? && x_in_tile.zero?
        draw_background_8pixels
      end
      if on_right_end_cycle?
        self.cycle = 0
        if on_bottom_end_line?
          self.line = 0
          deassert_nmi
          clear_sprite_hit
          clear_v_blank
          draw_sprites
          render_image
        else
          self.line += 1
          check_sprite_hit
          if on_line_to_start_v_blank?
            set_v_blank
            if v_blank_interrupt_enabled?
              assert_nmi
            end
          end
        end
      else
        self.cycle += 1
      end
    end

    # @param [Integer] index
    # @param [Integer] value
    def transfer_sprite_data(index:, value:)
      address = (@registers.sprite_ram_address + index) % SPRITE_RAM_BYTESIZE
      @sprite_ram.write(address, value)
    end

    # @param [Integer] address
    # @param [Integer] value
    # @return [Integer]
    def write(address, value)
      case address
      when 0x0000
        @registers.control = value
      when 0x0001
        @registers.mask = value
      when 0x0003
        @registers.sprite_ram_address = value
      when 0x0004
        write_to_sprite_ram_for_cpu(value)
      when 0x0005
        @registers.scroll = value
      when 0x0006
        @registers.video_ram_address = value
      when 0x0007
        write_to_video_ram_for_cpu(value)
      else
        raise ::Rnes::Errors::InvalidPpuAddressError, address
      end
    end

    private

    def assert_nmi
      @interrupt_line.assert_nmi
    end

    # @return [Integer]
    def base_name_table_address
      ADDRESS_TO_START_NAME_TABLE + @registers.base_name_table_id * 0x400
    end

    # @return [Integer]
    def base_background_pattern_table_address
      if registers.background_pattern_table_address_banked?
        0x1000
      else
        0x0000
      end
    end

    # @return [Integer]
    def base_sprite_pattern_table_address
      if registers.sprite_pattern_table_address_banked?
        0x1000
      else
        0x0000
      end
    end

    # +---+---+
    # | 0 | 1 |
    # +---+---+
    # | 2 | 3 |
    # +---+---+
    # @return [Integer] Integer from 0 to 3.
    def block_id_in_encoded_attributes
      (x_of_block.even? ? 0 : 1) + (y_of_block.even? ? 0 : 2)
    end

    def check_sprite_hit
      if read_from_sprite_ram(0) == y && @registers.background_enabled? && @registers.sprite_enabled?
        registers.sprite_hit = true
      end
    end

    def clear_sprite_hit
      registers.sprite_hit = false
    end

    def clear_v_blank
      registers.in_v_blank = false
    end

    def deassert_nmi
      @interrupt_line.deassert_nmi
    end

    def draw_background_8pixels
      pattern_index = read_pattern_index(background_pattern_index)
      pattern_line_low_byte_address = TILE_HEIGHT * 2 * pattern_index + y_in_tile
      pattern_line_low_byte = read_background_pattern_line(pattern_line_low_byte_address)
      pattern_line_high_byte = read_background_pattern_line(pattern_line_low_byte_address + TILE_HEIGHT)

      palette_ids_byte = read_object_attribute(object_attribute_index)
      palette_id = (palette_ids_byte >> (block_id_in_encoded_attributes * 2)) & 0b11

      TILE_WIDTH.times do |x_in_pattern|
        index_in_pattern_line_byte = TILE_WIDTH - 1 - x_in_pattern
        background_palette_index = pattern_line_low_byte[index_in_pattern_line_byte] | (pattern_line_high_byte[index_in_pattern_line_byte] << 1) | (palette_id << 2)
        color_id = read_color_id(background_palette_index)
        @image.write(
          value: ::Rnes::Ppu::COLORS[color_id],
          x: x + x_in_pattern,
          y: y,
        )
      end
    end

    # @note
    #   struct Sprite {
    #     U8 y;
    #     U8 tile;
    #     U8 attr;
    #     U8 x;
    #   }
    #
    # attr 76543210
    #      |||   `+- palette
    #      ||`------ priority (0: front, 1: back)
    #      |`------- horizontal flip
    #      `-------- vertical flip
    def draw_sprites
      0.step(SPRITES_COUNT - 1, 4) do |base_sprite_ram_address|
        y_for_sprite = read_from_sprite_ram(base_sprite_ram_address)
        pattern_index = read_from_sprite_ram(base_sprite_ram_address + 1)
        sprite_attribute_byte = read_from_sprite_ram(base_sprite_ram_address + 2)
        x_for_sprite = read_from_sprite_ram(base_sprite_ram_address + 3)

        palette_id = sprite_attribute_byte & 0b11
        reversed_horizontally = sprite_attribute_byte[6] == 1
        reversed_vertically = sprite_attribute_byte[7] == 1

        TILE_HEIGHT.times do |y_in_pattern|
          pattern_line_low_byte_address = TILE_HEIGHT * 2 * pattern_index + y_in_pattern
          pattern_line_low_byte = read_sprite_pattern_line(pattern_line_low_byte_address)
          pattern_line_high_byte = read_sprite_pattern_line(pattern_line_low_byte_address + TILE_HEIGHT)
          TILE_WIDTH.times do |x_in_pattern|
            index_in_pattern_line_byte = TILE_WIDTH - 1 - x_in_pattern
            sprite_palette_index = pattern_line_low_byte[index_in_pattern_line_byte] | (pattern_line_high_byte[index_in_pattern_line_byte] << 1) | (palette_id << 2)
            if sprite_palette_index % 4 != 0
              color_id = read_color_id(sprite_palette_index)
              y_in_pattern = TILE_HEIGHT - 1 - y_in_pattern if reversed_vertically
              x_in_pattern = TILE_WIDTH - 1 - x_in_pattern if reversed_horizontally
              @image.write(
                value: ::Rnes::Ppu::COLORS[color_id],
                x: x_for_sprite + x_in_pattern,
                y: y_for_sprite + y_in_pattern,
              )
            end
          end
        end
      end
    end

    # @return [Integer] Integer from 0 to 63.
    def object_attribute_index
      (y_of_encoded_attributes % ENCODED_ATTRIBUTES_COUNT_IN_VERTICAL_LINE) * ENCODED_ATTRIBUTES_COUNT_IN_HORIZONTAL_LINE +
        x_of_encoded_attributes % ENCODED_ATTRIBUTES_COUNT_IN_HORIZONTAL_LINE +
        background_pattern_index_paging_offset
    end

    # @return [Boolean]
    def on_bottom_end_line?
      line == WINDOW_HEIGHT + V_BLANK_HEIGHT
    end

    # @return [Boolean]
    def on_line_to_start_v_blank?
      line == WINDOW_HEIGHT
    end

    # @return [Boolean]
    def on_right_end_cycle?
      cycle == CYCLES_PER_LINE - 1
    end

    # @return [Boolean]
    def on_visible_cycle?
      (0...WINDOW_WIDTH).cover?(x) && (0...WINDOW_HEIGHT).cover?(y)
    end

    # @return [Boolean]
    def palette_data_requested?
      PALETTE_ADDRESS_RANGE.cover?(@registers.video_ram_address % 0x4000)
    end

    # @param [Integer] index.
    # @return [Integer]
    def read_background_pattern_line(index)
      read_pattern_line(base_background_pattern_table_address + index)
    end

    # @param [Integer] index
    # @return [Integer]
    def read_color_id(index)
      @bus.read(ADDRESS_TO_START_BACKGROUND_PALETTE_TABLE + index)
    end

    # @param [Integer] address
    # @return [Integer]
    def read_from_sprite_ram(address)
      @sprite_ram.read(address)
    end

    # @return [Integer]
    def read_from_video_ram_for_cpu
      if palette_data_requested?
        value = @bus.read(@registers.video_ram_address)
        @video_ram_reading_buffer = @bus.read(@registers.video_ram_address - 0x1000)
      else
        value = @video_ram_reading_buffer
        @video_ram_reading_buffer = @bus.read(@registers.video_ram_address)
      end
      @registers.increment_video_ram_address(video_ram_address_offset)
      value
    end

    # @param [Integer] index
    # @return [Integer] 4-color-palette IDs of 4 blocks, as 8 bit data.
    def read_object_attribute(index)
      @bus.read(ADDRESS_TO_START_ATTRIBUTE_TABLE + index)
    end

    # @param [Integer] index
    # @return [Integer]
    def read_pattern_line(index)
      @bus.read(index)
    end

    # @param [Integer] index.
    # @return [Integer]
    def read_sprite_pattern_line(index)
      read_pattern_line(base_sprite_pattern_table_address + index)
    end

    # @param [Integer] index
    # @return [Integer]
    def read_pattern_index(index)
      @bus.read(base_name_table_address + index)
    end

    def render_image
      @renderer.render(@image)
    end

    def set_v_blank
      registers.in_v_blank = true
    end

    # +-----------+-----------+
    # | 0(0x0000) | 1(0x0400) |
    # +-----------+-----------+
    # | 2(0x0800) | 3(0x0C00) |
    # +-----------+-----------+
    # @return [Integer] Integer from 0x0000 to 0x0FC0.
    def background_pattern_index
      background_pattern_index_in_window + background_pattern_index_paging_offset
    end

    # @return [Integer] Integer from 0x0000 to 0x03C0.
    def background_pattern_index_in_window
      (y_of_tile % TILES_COUNT_IN_VERTICAL_LINE) * TILES_COUNT_IN_HORIZONTAL_LINE + x_of_tile % TILES_COUNT_IN_HORIZONTAL_LINE
    end

    # @return [Integer] Integer from 0 to 3.
    def background_pattern_index_page
      x_of_tile / TILES_COUNT_IN_HORIZONTAL_LINE + y_of_tile / TILES_COUNT_IN_VERTICAL_LINE * 2
    end

    # @return [Integer] 0x0000, 0x0400, 0x0800, or 0x0C00.
    def background_pattern_index_paging_offset
      background_pattern_index_page * 0x0400
    end

    # @return [Boolean]
    def v_blank_interrupt_enabled?
      @registers.has_v_blank_irq_enabled_bit?
    end

    # @return [Integer]
    def video_ram_address_offset
      if registers.horizontal_increment?
        TILES_COUNT_IN_HORIZONTAL_LINE
      else
        1
      end
    end

    # @param [Integer] value
    def write_to_sprite_ram_for_cpu(value)
      @sprite_ram.write(@registers.sprite_ram_address, value)
      @registers.sprite_ram_address = (@registers.sprite_ram_address + 1) & 0xFF
    end

    # @param [Integer] value
    def write_to_video_ram_for_cpu(value)
      @bus.write(@registers.video_ram_address, value)
      @registers.increment_video_ram_address(video_ram_address_offset)
    end

    # @return [Integer]
    def x
      cycle - 1
    end

    # @return [Integer]
    def x_in_tile
      x_with_scroll % TILE_WIDTH
    end

    # @return [Integer]
    def x_of_block
      x_with_scroll / BLOCK_WIDTH
    end

    # @return [Integer]
    def x_of_encoded_attributes
      x_with_scroll / ENCODED_ATTRIBUTES_WIDTH
    end

    # @return [Integer]
    def x_of_tile
      x_with_scroll / TILE_WIDTH
    end

    # @return [Integer]
    def x_with_scroll
      x + @registers.scroll_x
    end

    # @return [Integer]
    def y
      line
    end

    # @return [Integer]
    def y_in_tile
      y_with_scroll % TILE_HEIGHT
    end

    # @return [Integer]
    def y_of_block
      y_with_scroll / BLOCK_HEIGHT
    end

    # @return [Integer]
    def y_of_encoded_attributes
      y_with_scroll / ENCODED_ATTRIBUTES_HEIGHT
    end

    # @return [Integer]
    def y_of_tile
      y_with_scroll / TILE_HEIGHT
    end

    # @return [Integer]
    def y_with_scroll
      y + @registers.scroll_y
    end
  end
end
