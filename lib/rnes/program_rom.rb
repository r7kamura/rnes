module Rnes
  class ProgramRom
    # @param [Integer] bytes
    def initialize(bytes)
      @bytes = bytes
    end

    # @return [Integer]
    def bytesize
      @bytes.length
    end

    # @param [Integer] address
    # @param [Integer] value
    def read(address)
      @bytes[address]
    end

    def write(address, value)
      @bytes[address] = value
    end
  end
end
