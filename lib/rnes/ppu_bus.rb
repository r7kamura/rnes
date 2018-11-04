require 'rnes/errors'

module Rnes
  class PpuBus
    # @return [Rnes::Ram]
    attr_reader :character_ram

    # @param [Rnes::Ram] character_ram
    # @param [Rnes::Ram] sprite_ram
    # @param [Rnes::Ram] video_ram
    def initialize(character_ram:, video_ram:)
      @character_ram = character_ram
      @video_ram = video_ram
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      case address
      when 0x0000..0x1FFF
        @character_ram.read(address)
      when 0x2000..0x27FF
        @video_ram.read(address - 0x2000)
      when 0x2800..0x2FFF
        read(address - 0x0800)
      when 0x3000..0x3EFF
        read(address - 0x1000)
      when 0x3F00..0x3F1F
        @video_ram.read(address - 0x2000)
      when 0x3F20..0x3FFF
        read(address - 0x20) # mirror to 0x3F00..0x3F1F
      when 0x4000..0xFFFF
        read(address - 0x4000) # mirror to 0x0000..0x3FFF
      else
        raise ::Rnes::Errors::InvalidPpuBusAddressError, address
      end
    end

    # @param [Integer] address
    # @param [Integer] value
    def write(address, value)
      case address
      when 0x0000..0x1FFF
        @character_ram.write(address, value)
      when 0x2000..0x27FF
        @video_ram.write(address - 0x2000, value)
      when 0x2800..0x2FFF
        @video_ram.write(address - 0x0800, value)
      when 0x3000..0x3EFF
        @video_ram.write(address - 0x1000, value)
      when 0x3F00..0x3F1F
        @video_ram.write(address - 0x2000, value)
      when 0x3F00..0xFFFF
        write(address - 0x1000, value)
      else
        raise ::Rnes::Errors::InvalidPpuBusAddressError, address
      end
    end
  end
end
