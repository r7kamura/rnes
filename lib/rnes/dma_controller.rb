module Rnes
  class DmaController
    TRANSFER_BYTESIZE = 2**8

    # @param [Rnes::Ppu] ppu
    # @param [Rnes::Ram] working_ram
    def initialize(ppu:, working_ram:)
      @ppu = ppu
      @requested = false
      @working_ram = working_ram
    end

    def transfer_if_requested
      if @requested
        transfer
      end
    end

    # @param [Integer] address_hint
    def request_transfer(address_hint:)
      @requested = true
      @working_ram_address = address_hint << 8
    end

    private

    def transfer
      TRANSFER_BYTESIZE.times do |index|
        value = @working_ram.read(@working_ram_address + index)
        @ppu.transfer_sprite_data(index: index, value: value)
      end
      @requested = false
    end
  end
end
