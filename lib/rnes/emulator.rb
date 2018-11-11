require 'io/console'
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
      @keypad1 = parts_factory.keypad1
      @keypad2 = parts_factory.keypad2
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
      allow_break_less_input
      $stdin.noecho do
        loop do
          if @logger
            @logger.puts
          end
          step
        end
      end
    ensure
      disallow_break_less_input
    end

    def step
      @dma_controller.transfer_if_requested
      (@cpu.step * 3).times do
        @ppu.step
      end
      @keypad1.check
      @keypad2.check
    end

    private

    def allow_break_less_input
      `stty -icanon min 1 time 0`
    end

    def disallow_break_less_input
      `stty icanon`
    end

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
