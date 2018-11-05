require 'rnes/cpu_bus'
require 'rnes/cpu'
require 'rnes/dma_controller'
require 'rnes/interrupt_line'
require 'rnes/ppu'
require 'rnes/ppu_bus'
require 'rnes/ram'
require 'rnes/rom'
require 'rnes/terminal_renderer'

module Rnes
  class PartsFactory
    CHARACTER_RAM_BYTESIZE = 2**12

    VIDEO_RAM_BYTESIZE = 2**13

    WORKING_RAM_BYTESIZE = 2**11

    # @return [Rnes::Ram]
    def character_ram
      @character_ram ||= ::Rnes::Ram.new(bytesize: CHARACTER_RAM_BYTESIZE)
    end

    # @return [Rnes::Cpu]
    def cpu
      @cpu ||= ::Rnes::Cpu.new(
        bus: cpu_bus,
        interrupt_line: interrupt_line,
      )
    end

    # @return [Rnes::CpuBus]
    def cpu_bus
      @cpu_bus ||= ::Rnes::CpuBus.new(
        dma_controller: dma_controller,
        ppu: ppu,
        ram: working_ram,
      )
    end

    # @return [Rnes::DmaController]
    def dma_controller
      @dma_controller ||= ::Rnes::DmaController.new(
        ppu: ppu,
        working_ram: working_ram,
      )
    end

    # @return [Rnes::InterruptLine]
    def interrupt_line
      @interrupt_line ||= ::Rnes::InterruptLine.new
    end

    # @return [Rnes::Ppu]
    def ppu
      @ppu ||= ::Rnes::Ppu.new(
        bus: ppu_bus,
        interrupt_line: interrupt_line,
        renderer: renderer,
      )
    end

    # @return [Rnes::PpuBus]
    def ppu_bus
      @ppu_bus ||= ::Rnes::PpuBus.new(
        character_ram: character_ram,
        video_ram: video_ram,
      )
    end

    # @return [Rnes::TerminalRenderer]
    def renderer
      @renderer ||= ::Rnes::TerminalRenderer.new
    end

    # @return [Rnes::Ram]
    def video_ram
      @video_ram ||= ::Rnes::Ram.new(bytesize: VIDEO_RAM_BYTESIZE)
    end

    # @return [Rnes::Ram]
    def working_ram
      @working_ram ||= ::Rnes::Ram.new(bytesize: WORKING_RAM_BYTESIZE)
    end
  end
end
