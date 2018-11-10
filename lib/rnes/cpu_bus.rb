require 'rnes/errors'

module Rnes
  class CpuBus
    # @param [Rnes::Rom]
    # @return [Rnes::Rom]
    attr_accessor :program_rom

    # @param [Rnes::DmaController] dma_controller
    # @param [Rnes::Keypad] keypad1
    # @param [Rnes::Keypad] keypad2
    # @param [Rnes::Ppu] ppu
    # @param [Rnes::Ram] ram
    def initialize(dma_controller:, keypad1:, keypad2:, ppu:, ram:)
      @dma_controller = dma_controller
      @keypad1 = keypad1
      @keypad2 = keypad2
      @ppu = ppu
      @ram = ram
    end

    # @param [Integer]
    # @return [Integer]
    def read(address)
      case address
      when 0x0000..0x07FF
        @ram.read(address)
      when 0x0800..0x1FFF
        @ram.read(address - 0x0800)
      when 0x2000..0x2007
        @ppu.read(address - 0x2000)
      when 0x2008..0x3FFF
        read(address - 0x0008)
      when 0x4016
        @keypad1.read
      when 0x4017
        @keypad2.read
      when 0x4000..0x401F
        0 # TODO: I/O port for APU, etc
      when 0x4020..0x5FFF
        0 # TODO: extended RAM on special mappers
      when 0x6000..0x7FFF
        0 # TODO: battery-backed-up RAM
      when 0x8000..0xBFFF
        try_to_read_program_rom(address - 0x8000)
      when 0xC000..0xFFFF
        try_to_read_program_rom(address - offset_on_reading_program_rom_higher_region)
      else
        raise ::Rnes::Errors::InvalidCpuBusAddressError, address
      end
    end

    # @param [Integer] address
    # @param [Integer] value
    def write(address, value)
      case address
      when 0x0000..0x07FF
        @ram.write(address, value)
      when 0x0800..0x1FFF
        @ram.write(address - 0x0800, value)
      when 0x2000..0x2007
        @ppu.write(address - 0x2000, value)
      when 0x2008..0x3FFF
        write(address - 0x0008, value)
      when 0x4014
        @dma_controller.request_transfer(address_hint: value)
      when 0x4016
        @keypad1.write(value)
      when 0x4017
        @keypad2.write(value)
      when 0x4000..0x401F
        # TODO: I/O port for APU, etc
      when 0x4020..0x5FFF
        # TODO: extended RAM on special mappers
      when 0x6000..0x7FFF
        # TODO: battery-backed-up RAM
      when 0x8000..0xFFFF
      else
        raise ::Rnes::Errors::InvalidCpuBusAddressError, address
      end
    end

    private

    # @return [Boolean]
    def attatched_to_large_program_rom?
      @program_rom.bytesize > 16 * 2**10
    end

    # @return [Integer]
    def offset_on_reading_program_rom_higher_region
      attatched_to_large_program_rom? ? 0x8000 : 0xC000
    end

    # @param [Integer] address
    def try_to_read_program_rom(address)
      if @program_rom
        @program_rom.read(address)
      else
        raise ::Rnes::Errors::ProgramRomNotConnectedError
      end
    end
  end
end
