module Rnes
  class Ram
    # @todo
    def initialize
      @bytes = Array.new(2 * 2**10).map do
        0
      end
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bytes[address]
    end

    def write(address, value)
      @bytes[address] = value
    end
  end
end
