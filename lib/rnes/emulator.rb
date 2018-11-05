require 'rnes/parts_factory'
require 'rnes/rom'
require 'rnes/rom_loader'

module Rnes
  class Emulator
    LOG_FILE_NAME = 'rnes.log'.freeze

    # @return [Rnes::CpuBus]
    attr_reader :cpu_bus

    # @return [Rnes::PpuBus]
    attr_reader :ppu_bus

    def initialize
      parts_factory = ::Rnes::PartsFactory.new
      @cpu = parts_factory.cpu
      @cpu_bus = parts_factory.cpu_bus
      @dma_controller = parts_factory.dma_controller
      @ppu = parts_factory.ppu
      @ppu_bus = parts_factory.ppu_bus
    end

    # @param [Array<Integer>] rom_bytes
    def load_rom(rom_bytes)
      rom_loader = ::Rnes::RomLoader.new(rom_bytes)
      character_rom_bytes = rom_loader.character_rom_bytes
      character_rom_bytes.length.times do |i|
        @ppu_bus.character_ram.write(i, character_rom_bytes[i])
      end
      @cpu_bus.program_rom = ::Rnes::Rom.new(bytes: rom_loader.program_rom_bytes)
      @cpu.reset
    end

    def run
      loop do
        tick
      end
    end

    def run_with_logging
      loop do
        puts_log_line
        tick
      end
    end

    def tick
      @dma_controller.transfer_if_requested
      @cpu.tick
      @ppu.tick
      @ppu.tick
      @ppu.tick
    end

    private

    # @return [File]
    def log_file
      @log_file ||= ::File.open(LOG_FILE_NAME, 'w')
    end

    # @return [String]
    def log_line
      [
        log_segment_cpu_program_counter,
        '',
        log_segment_operation_code,
        log_segment_operand,
        log_segment_operation_full_name,
        log_segment_operand_humanized,
        '',
        log_segment_cpu_accumulator,
        log_segment_cpu_index_x,
        log_segment_cpu_index_y,
        log_segment_cpu_status,
        log_segment_cpu_stack_pointer,
        log_segment_cycle,
        log_segment_ppu_line,
      ].join(' ')
    end

    # @return [String]
    def log_segment_cpu_accumulator
      format('A:%02X', @cpu.registers.accumulator)
    end

    # @return [String]
    def log_segment_cpu_index_x
      format('X:%02X', @cpu.registers.index_x)
    end

    # @return [String]
    def log_segment_cpu_index_y
      format('Y:%02X', @cpu.registers.index_y)
    end

    # @return [String]
    def log_segment_cpu_program_counter
      format('%04X', @cpu.registers.program_counter)
    end

    # @return [String]
    def log_segment_cpu_stack_pointer
      format('SP:%02X', @cpu.registers.stack_pointer - 0x100)
    end

    # @return [String]
    def log_segment_cpu_status
      format('P:%08b', @cpu.registers.status)
    end

    # @return [String]
    def log_segment_cycle
      format('CYC:%03d', @ppu.cycle)
    end

    # @return [String]
    def log_segment_operand
      program_counter = @cpu.registers.program_counter
      operation = @cpu.read_operation
      case operation.addressing_mode
      when :absolute, :absolute_x, :absolute_y, :indirect_absolute, :pre_indexed_absolute, :post_indexed_absolute
        format('%02X %02X', @cpu.bus.read(program_counter + 1), @cpu.bus.read(program_counter + 2))
      when :immediate, :relative, :zero_page, :zero_page_x, :zero_page_y
        format('%02X   ', @cpu.bus.read(program_counter + 1))
      else
        ' ' * 5
      end
    end

    # @return [String]
    def log_segment_operand_humanized
      operation = @cpu.read_operation
      program_counter = @cpu.registers.program_counter
      string = begin
        case operation.addressing_mode
        when :absolute, :absolute_x, :absolute_y, :indirect_absolute, :pre_indexed_absolute, :post_indexed_absolute
          format('$%02X%02X', @cpu.bus.read(program_counter + 2), @cpu.bus.read(program_counter + 1))
        when :immediate, :relative, :zero_page, :zero_page_x, :zero_oage_y
          format('#$%02X', @cpu.bus.read(program_counter + 1))
        else
          ''
        end
      end
      format('%-5s', string)
    end

    # @return [String]
    def log_segment_operation_code
      operation = @cpu.read_operation
      operation_code = ::Rnes::Operation::RECORDS.find_index(operation.to_hash)
      format('%02X', operation_code)
    end

    # @return [String]
    def log_segment_operation_full_name
      operation = @cpu.read_operation
      format('%8s', operation.full_name)
    end

    # @note SL means "Scan Line".
    # @return [String]
    def log_segment_ppu_line
      format('SL:%03d', @ppu.line)
    end

    def puts_log_line
      log_file.puts(log_line)
    end
  end
end
