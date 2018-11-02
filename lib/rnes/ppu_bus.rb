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
      when 0x2000..0x27FF
        @ram.read(address - 0x2000)
      when 0x2800..0x2FFF
        @ram.read(address - 0x0800)
      when 0x3000..0x3EFF
        @ram.read(address - 0x1000)
      when 0x3F00..0x3E0F
        # TODO: backgroud palette table
      when 0x3F10..0x3F1F
        # TODO: sprite palette table
      when 0x3F20..0x3FFF
        read(address - 20) # mirror to 0x3F00..0x3F1F
      when 0x4000..0xFFFF
        read(address - 4000) # mirror to 0x0000..0x3FFF
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
