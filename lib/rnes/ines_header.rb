module Rnes
  class InesHeader
    BYTESIZE = 16

    PREFIX_BYTES = [
      0x4E, # N
      0x45, # E
      0x53, # S
      0x1A, # end-of-file in MS-DOS
    ]

    # @param [Array<Integer>] data
    def initialize(data)
      @data = data
    end

    # @return [Integer]
    def bytesize
      BYTESIZE
    end

    # @return [Integer]
    def character_ram_bytesize
      @data[8]
    end

    # @return [Integer]
    def character_rom_bytesize
      @data[5] * 8 * 2 ** 10
    end

    # @return [Boolean]
    def has_battery_backed_program_rom?
      flags1[1] == 1
    end

    # @note Trainers are 512 bytes of code which is loaded into $7000 before the game starts for hacker use.
    # @return [Boolean]
    def has_trainer?
      flags1[2] == 1
    end

    # @return [Boolean]
    def has_vertical_mirroring?
      flags1[0] == 1
    end

    # @return [Boolean]
    def has_mirror_ignoring?
      flags1[3] == 1
    end

    # @return [Integer]
    def mapper_number
      flags2 & 0b11110000 | flags1 >> 4
    end

    # @return [Integer]
    def program_rom_bytesize
      @data[4] * 16 * 2 ** 10
    end

    # @return [Integer]
    def trainer_bytesize
      if has_trainer?
        512
      else
        0
      end
    end

    # @return [Boolean]
    def valid?
      @data[0..3] == PREFIX_BYTES
    end

    private

    # @return [Integer]
    def flags1
      @data[6]
    end

    # @return [Integer]
    def flags2
      @data[7]
    end
  end
end
