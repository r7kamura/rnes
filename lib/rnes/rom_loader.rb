require 'rnes/errors'
require 'rnes/ines_header'

module Rnes
  class RomLoader
    # @param [Array<Integer>] bytes
    def initialize(bytes)
      @bytes = bytes
    end

    # @return [Array<Integer>]
    def character_rom_bytes
      validate!
      @bytes.slice(character_rom_index, character_rom_bytesize)
    end

    # @return [Array<Integer>]
    def program_rom_bytes
      validate!
      @bytes.slice(program_rom_index, program_rom_bytesize)
    end

    # @return [Array<Integer>]
    def trainer_bytes
      validate!
      @bytes.slice(trainer_index, trainer_bytesize)
    end

    # @return [Boolean]
    def valid?
      ines_header.valid?
    end

    private

    # @return [Integer]
    def character_rom_bytesize
      ines_header.character_rom_bytesize
    end

    # @return [Integer]
    def character_rom_index
      program_rom_index + program_rom_bytesize
    end

    # @return [Rnes::InesHeader]
    def ines_header
      @ines_header ||= ::Rnes::InesHeader.new(@bytes)
    end

    # @return [Integer]
    def program_rom_bytesize
      @program_rom_bytesize ||= ines_header.program_rom_bytesize
    end

    # @return [Integer]
    def program_rom_index
      @program_rom_index ||= trainer_index + trainer_bytesize
    end

    # @return [Integer]
    def trainer_bytesize
      ines_header.trainer_bytesize
    end

    # @return [Integer]
    def trainer_index
      ines_header.bytesize
    end

    # @raise [Rnes::Errors::InvalidInesFormatError]
    def validate!
      unless valid?
        raise ::Rnes::Errors::InvalidInesFormatError
      end
    end
  end
end
