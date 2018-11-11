require 'rnes/errors'
require 'rnes/image'
require 'rnes/ppu_registers'
require 'rnes/ppu/colors'
require 'rnes/ram'

module Rnes
  class Ppu
    ADDRESS_TO_START_ATTRIBUTE_TABLE = 0x23C0

    ADDRESS_TO_START_NAME_TABLE = 0x2000

    ADDRESS_TO_START_BACKGROUND_PALETTE_TABLE = 0x3F00

    ADDRESS_TO_START_SPRITE_PALETTE_TABLE = 0x3F10

    BLOCK_HEIGHT = 16

    BLOCK_WIDTH = 16

    CYCLES_PER_LINE = 341

    SPRITE_RAM_BYTESIZE = 2**8

    SPRITES_COUNT = 64

    TILE_HEIGHT = 8

    TILE_WIDTH = 8

    V_BLANK_HEIGHT = 21

    WINDOW_HEIGHT = 240

    WINDOW_WIDTH = 256

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
      @sprite_ram_address = 0x00
      @requested_video_ram_data_address = 0x0000
      @video_ram_reading_buffer = 0x00
      @writing_to_scroll_registers = false
      @writing_video_ram_address = false
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
        @writing_to_scroll_registers = false
        value = registers.status
        clear_v_blank
        value
      when 0x0004
        read_from_sprite_ram(@sprite_ram_address)
      when 0x0007
        read_requested_video_ram_data
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
      address = (@sprite_ram_address + index) % SPRITE_RAM_BYTESIZE
      @sprite_ram.write(address, value)
    end

    # @param [Integer] address
    # @param [Integer] value
    # @return [Integer]
    def write(address, value)
      case address
      when 0x0000
        registers.control = value
      when 0x0001
        registers.mask = value
      when 0x0003
        write_sprite_ram_address(value)
      when 0x0004
        write_to_sprite_ram_via_ppu_read(value)
      when 0x0005
        write_to_scroll_registers(value)
      when 0x0006
        write_video_ram_address(value)
      when 0x0007
        write_to_video_ram(value)
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
      base_pattern_table_address = base_background_pattern_table_address
      character_index = read_character_index(tile_index)
      character_line_low_byte_address = TILE_HEIGHT * 2 * character_index + y_in_tile + base_pattern_table_address
      character_line_low_byte = read_character_data(character_line_low_byte_address)
      character_line_high_byte = read_character_data(character_line_low_byte_address + TILE_HEIGHT)

      block_id = 0
      block_id |= 0b01 if (x % BLOCK_WIDTH).odd?
      block_id |= 0b10 if (y % BLOCK_HEIGHT).odd?
      mini_palette_ids_byte = read_object_attribute(tile_index)
      mini_palette_id = (mini_palette_ids_byte >> (block_id * 2)) & 0b11

      TILE_WIDTH.times do |x_in_character|
        index_in_character_line_byte = TILE_WIDTH - 1 - x_in_character
        background_palette_index = character_line_low_byte[index_in_character_line_byte] | character_line_high_byte[index_in_character_line_byte] << 1 | mini_palette_id << 2
        color_id = read_color_id(background_palette_index)
        @image.write(
          value: ::Rnes::Ppu::COLORS[color_id],
          x: x + x_in_character,
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
      base_pattern_table_address = base_sprite_pattern_table_address
      SPRITES_COUNT.times do |i|
        base_sprite_ram_address = i * 4
        y_for_sprite = (read_from_sprite_ram(base_sprite_ram_address) - TILE_HEIGHT)
        next if y_for_sprite.negative?
        name_table_index = read_from_sprite_ram(base_sprite_ram_address + 1)
        sprite_attribute_byte = read_from_sprite_ram(base_sprite_ram_address + 2)
        x_for_sprite = read_from_sprite_ram(base_sprite_ram_address + 3)

        character_index = read_character_index(name_table_index)

        mini_palette_id = sprite_attribute_byte & 0b11

        TILE_HEIGHT.times do |y_in_character|
          character_line_low_byte_address = TILE_HEIGHT * 2 * character_index + y_in_character + base_pattern_table_address
          character_line_low_byte = read_character_data(character_line_low_byte_address)
          character_line_high_byte = read_character_data(character_line_low_byte_address + TILE_HEIGHT)
          TILE_WIDTH.times do |x_in_character|
            index_in_character_line_byte = TILE_WIDTH - 1 - x_in_character
            background_palette_index = character_line_low_byte[index_in_character_line_byte] | character_line_high_byte[index_in_character_line_byte] << 1 | mini_palette_id << 2
            color_id = read_color_id(background_palette_index)
            @image.write(
              value: ::Rnes::Ppu::COLORS[color_id],
              x: x_for_sprite + x_in_character,
              y: y_for_sprite + y_in_character,
            )
          end
        end
      end
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

    # @param [Integer] index
    # @return [Integer]
    def read_character_data(index)
      @bus.read(index)
    end

    # @param [Integer] index
    # @return [Integer]
    def read_character_index(index)
      @bus.read(base_name_table_address + index)
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

    # @param [Integer] index
    # @return [Integer] 4-color-palette IDs of 4 blocks, as 8 bit data.
    def read_object_attribute(index)
      @bus.read(ADDRESS_TO_START_ATTRIBUTE_TABLE + index)
    end

    # @return [Integer]
    def read_requested_video_ram_data
      if (0x3F00..0x3F1F).cover?(@requested_video_ram_data_address % 0x4000)
        value = @bus.read(@requested_video_ram_data_address)
        @video_ram_reading_buffer = @bus.read(@requested_video_ram_data_address - 0x1000)
      else
        value = @video_ram_reading_buffer
        @video_ram_reading_buffer = @bus.read(@requested_video_ram_data_address)
      end
      @requested_video_ram_data_address += video_ram_address_offset
      value
    end

    def render_image
      @renderer.render(@image)
    end

    def set_v_blank
      registers.set_in_v_blank_bit
    end

    # +-----------+-----------+
    # | 0(0x0000) | 1(0x0400) |
    # +-----------+-----------+
    # | 2(0x0800) | 3(0x0C00) |
    # +-----------+-----------+
    # @return [Integer] Integer from 0x0000 to 0x0FC0.
    def tile_index
      tile_index_in_window + tile_index_paging_offset
    end

    # @return [Integer] Integer from 0x0000 to 0x03C0.
    def tile_index_in_window
      (y_of_tile % TILES_COUNT_IN_VERTICAL_LINE) * TILES_COUNT_IN_HORIZONTAL_LINE + x_of_tile % TILES_COUNT_IN_HORIZONTAL_LINE
    end

    # @return [Integer] Integer from 0 to 3.
    def tile_index_page
      x_of_tile / TILES_COUNT_IN_HORIZONTAL_LINE + y_of_tile / TILES_COUNT_IN_VERTICAL_LINE * 2
    end

    # @return [Integer] 0x0000, 0x0400, 0x0800, or 0x0C00.
    def tile_index_paging_offset
      tile_index_page * 0x0400
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

    # @param [Integer] address
    def write_sprite_ram_address(address)
      @sprite_ram_address = address
    end

    # @param [Integer] value
    def write_to_scroll_registers(value)
      if @writing_to_scroll_registers
        @registers.scroll_y = value
      else
        @registers.scroll_x = value
      end
      @writing_to_scroll_registers = !@writing_to_scroll_registers
    end

    # @param [Integer] value
    def write_to_sprite_ram_via_ppu_read(value)
      @sprite_ram.write(@sprite_ram_address, value)
      @sprite_ram_address += 1
    end

    # @param [Integer] address
    def write_video_ram_address(address)
      if @writing_video_ram_address
        @requested_video_ram_data_address |= address
      else
        @requested_video_ram_data_address = address << 8
      end
      @writing_video_ram_address = !@writing_video_ram_address
    end

    # @param [Integer] value
    def write_to_video_ram(value)
      @bus.write(@requested_video_ram_data_address, value)
      @requested_video_ram_data_address += video_ram_address_offset
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
      (x + @registers.scroll_x) / TILE_WIDTH
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
      (y + @registers.scroll_y) / TILE_HEIGHT
    end
  end
end
