require 'rnes/errors'

module Rnes
  class PpuBus
    # @param [Rnes::CharacterRom]
    # @return [Rnes::CharacterRom]
    attr_accessor :character_rom

    # @param [Rnes::Ram] ram
    def initialize(ram:)
      @ram = ram
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      case address
      when 0x0000..0x1FFF
        try_to_read_character_rom(address)
      when 0x2000..0x2FFF
        @ram.read(address - 0x2000)
      else
        raise ::Rnes::Errors::InvalidPpuBusAddressError, "Invalid address: #{address}"
      end
    end

    private

    # @param [Integer] address
    def try_to_read_character_rom(address)
      if @character_rom
        @character_rom.read(address)
      else
        raise ::Rnes::Errors::CharacterRomNotConnectedError
      end
    end
  end
end
