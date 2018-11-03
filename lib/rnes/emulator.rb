require 'rnes/character_rom'
require 'rnes/cpu_bus'
require 'rnes/cpu'
require 'rnes/ppu'
require 'rnes/program_rom'
require 'rnes/ram'
require 'rnes/rom_loader'

module Rnes
  class Emulator
    # @return [Rnes::CpuBus]
    attr_reader :cpu_bus

    # @return [Rnes::PpuBus]
    attr_reader :ppu_bus

    def initialize
      @video_ram = ::Rnes::Ram.new
      @working_ram = ::Rnes::Ram.new
      @ppu_bus = ::Rnes::PpuBus.new(ram: @video_ram)
      @ppu = ::Rnes::Ppu.new(bus: @ppu_bus)
      @cpu_bus = ::Rnes::CpuBus.new(ppu: @ppu, ram: @working_ram)
      @cpu = ::Rnes::Cpu.new(bus: @cpu_bus)
    end

    # @param [Array<Integer>] rom_bytes
    def load_rom(rom_bytes)
      rom_loader = ::Rnes::RomLoader.new(rom_bytes)
      @cpu_bus.program_rom = ::Rnes::ProgramRom.new(rom_loader.program_rom_bytes)
      @ppu_bus.character_rom = ::Rnes::CharacterRom.new(rom_loader.character_rom_bytes)
      @cpu.reset
    end

    def run
      loop do
        tick
      end
    end

    def tick
      @cpu.tick
      @ppu.tick
      @ppu.tick
      @ppu.tick
    end
  end
end
