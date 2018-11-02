module Rnes
  class CharacterRom
    # @param [Integer] bytes
    def initialize(bytes)
      @bytes = bytes
    end

    # @return [Integer]
    def bytesize
      @bytes.length
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bytes[address]
    end
  end
end
