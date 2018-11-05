require 'rnes/logger'
require 'rnes/parts_factory'
require 'rnes/rom_loader'

module Rnes
  class Emulator
    LOG_FILE_NAME = 'rnes.log'.freeze

    def initialize
      parts_factory = ::Rnes::PartsFactory.new
      @cpu = parts_factory.cpu
      @cpu_bus = parts_factory.cpu_bus
      @dma_controller = parts_factory.dma_controller
      @ppu = parts_factory.ppu
      @ppu_bus = parts_factory.ppu_bus
      @logger = ::Rnes::Logger.new(cpu: @cpu, path: LOG_FILE_NAME, ppu: @ppu)
    end

    # @param [Array<Integer>] rom_bytes
    def load_rom(rom_bytes)
      rom_loader = ::Rnes::RomLoader.new(rom_bytes)
      copy(from: rom_loader.character_rom, to: @ppu_bus.character_ram)
      @cpu_bus.program_rom = rom_loader.program_rom
      @cpu.reset
    end

    def run
      loop do
        tick
      end
    end

    def run_with_logging
      loop do
        @logger.puts
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

    # @param [Rnes::Rom] from
    # @param [Rnes::Ram] to
    def copy(from:, to:)
      from.bytesize.times do |address|
        value = from.read(address)
        to.write(address, value)
      end
    end
  end
end
