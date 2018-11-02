module Rnes
  class PpuBus
    # @param [Rnes::CharacterRom]
    # @return [Rnes::CharacterRom]
    attr_accessor :character_rom

    # @todo
    # @param [Integer] address
    # @return [Integer]
    def read(address)
      0
    end
  end
end
