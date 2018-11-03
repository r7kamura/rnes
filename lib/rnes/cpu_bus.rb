require 'rnes/errors'

module Rnes
  class CpuBus
    # @param [Rnes::ProgramRom]
    # @return [Rnes::ProgramRom]
    attr_accessor :program_rom

    # @param [Rnes::Ppu] ppu
    # @param [Rnes::Ram] ram
    def initialize(ppu:, ram:)
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
        @ppu.read(address - 0x2008)
      when 0x4000..0x401F
        0 # TODO
      when 0x4020..0x5FFF
        # TODO
      when 0x6000..0x7FFF
        # TODO
      when 0x8000..0xBFFF
        try_to_read_program_rom(address - 0x8000)
      when 0xC000..0xFFFF
        try_to_read_program_rom(address - offset_on_reading_program_rom_higher_region)
      else
        raise ::Rnes::Errors::InvalidCpuBusAddressError, "Invalid address: #{address}"
      end
    end

    # @todo
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
        @ppu.write(address - 0x2008, value)
      when 0x4000..0x401F
        # TODO
      when 0x4020..0x5FFF
        # TODO
      when 0x6000..0x7FFF
        # TODO
      else
        raise ::Rnes::Errors::InvalidCpuBusAddressError, "Invalid address: #{address}"
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
