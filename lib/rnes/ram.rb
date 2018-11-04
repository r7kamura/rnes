module Rnes
  class Ram
    # @param [Integer] bytesize
    def initialize(bytesize:)
      @bytes = Array.new(bytesize).map do
        0
      end
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bytes[address]
    end

    # @param [Integer] address
    # @param [Integer] value
    # @return [Integer]
    def write(address, value)
      @bytes[address] = value
    end
  end
end
