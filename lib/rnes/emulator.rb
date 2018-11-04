require 'rnes/cpu_bus'
require 'rnes/cpu'
require 'rnes/ppu'
require 'rnes/program_rom'
require 'rnes/ram'
require 'rnes/rom_loader'

module Rnes
  class Emulator
    CHARACTER_RAM_BYTESIZE = 2**12

    LOG_FILE_NAME = 'rnes.log'.freeze

    VIDEO_RAM_BYTESIZE = 2**13

    WORKING_RAM_BYTESIZE = 2**11

    class << self
      # @return [Rnes::Ram]
      def generate_character_ram
        ::Rnes::Ram.new(bytesize: CHARACTER_RAM_BYTESIZE)
      end

      # @return [Rnes::Ram]
      def generate_video_ram
        ::Rnes::Ram.new(bytesize: VIDEO_RAM_BYTESIZE)
      end

      # @return [Rnes::Ram]
      def generate_working_ram
        ::Rnes::Ram.new(bytesize: WORKING_RAM_BYTESIZE)
      end
    end

    # @return [Rnes::CpuBus]
    attr_reader :cpu_bus

    # @return [Rnes::PpuBus]
    attr_reader :ppu_bus

    def initialize
      @ppu_bus = ::Rnes::PpuBus.new(
        character_ram: self.class.generate_character_ram,
        video_ram: self.class.generate_video_ram,
      )
      @ppu = ::Rnes::Ppu.new(
        bus: @ppu_bus,
      )
      @cpu_bus = ::Rnes::CpuBus.new(
        ppu: @ppu,
        ram: self.class.generate_working_ram,
      )
      @cpu = ::Rnes::Cpu.new(
        bus: @cpu_bus,
      )
    end

    # @param [Array<Integer>] rom_bytes
    def load_rom(rom_bytes)
      rom_loader = ::Rnes::RomLoader.new(rom_bytes)
      character_rom_bytes = rom_loader.character_rom_bytes
      character_rom_bytes.length.times do |i|
        @ppu_bus.character_ram.write(i, character_rom_bytes[i])
      end
      @cpu_bus.program_rom = ::Rnes::ProgramRom.new(rom_loader.program_rom_bytes)
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
        log_segment_operation_code,
        log_segment_operation_name,
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
      format('A:0x%02X', @cpu.registers.accumulator)
    end

    # @return [String]
    def log_segment_cpu_index_x
      format('X:0x%02X', @cpu.registers.index_x)
    end

    # @return [String]
    def log_segment_cpu_index_y
      format('Y:0x%02X', @cpu.registers.index_y)
    end

    # @return [String]
    def log_segment_cpu_program_counter
      format('PC:0x%04X', @cpu.registers.program_counter)
    end

    # @return [String]
    def log_segment_cpu_stack_pointer
      format('SP:0x%02X', @cpu.registers.stack_pointer - 0x100)
    end

    # @return [String]
    def log_segment_cpu_status
      format('P:0b%08b', @cpu.registers.status)
    end

    # @return [String]
    def log_segment_cycle
      format('CYC:%03d', @ppu.cycle)
    end

    # @return [String]
    def log_segment_operation_code
      operation = @cpu.read_operation
      operation_code = ::Rnes::Operation::RECORDS.find_index(operation.to_hash)
      format('OP:0x%02X', operation_code)
    end

    # @return [String]
    def log_segment_operation_name
      operation = @cpu.read_operation
      format('%-4s', operation.name)
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
