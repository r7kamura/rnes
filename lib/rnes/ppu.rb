module Rnes
  class Ppu
    # @param [Rnes::PpuBus] bus
    def initialize(bus:)
      @bus = bus
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bus.read(address)
    end

    # @todo
    def tick
    end
  end
end
