require 'rnes/errors'
require 'rnes/ines_header'
require 'rnes/rom'

module Rnes
  class RomLoader
    # @param [Array<Integer>] bytes
    def initialize(bytes)
      @bytes = bytes
    end

    # @return [Rnes::Rom]
    def character_rom
      validate!
      ::Rnes::Rom.new(bytes: character_rom_bytes)
    end

    # @return [Rnes::Rom]
    def program_rom
      validate!
      ::Rnes::Rom.new(bytes: program_rom_bytes)
    end

    # @return [Rnes::Rom]
    def trainer_rom
      validate!
      ::Rnes::Rom.new(bytes: trainer_bytes)
    end

    private

    # @return [Array<Integer>]
    def character_rom_bytes
      @bytes.slice(character_rom_index, character_rom_bytesize)
    end

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

    # @return [Array<Integer>]
    def program_rom_bytes
      @bytes.slice(program_rom_index, program_rom_bytesize)
    end

    # @return [Integer]
    def program_rom_bytesize
      @program_rom_bytesize ||= ines_header.program_rom_bytesize
    end

    # @return [Integer]
    def program_rom_index
      @program_rom_index ||= trainer_index + trainer_bytesize
    end

    # @return [Array<Integer>]
    def trainer_bytes
      @bytes.slice(trainer_index, trainer_bytesize)
    end

    # @return [Integer]
    def trainer_bytesize
      ines_header.trainer_bytesize
    end

    # @return [Integer]
    def trainer_index
      ines_header.bytesize
    end

    # @return [Boolean]
    def valid?
      ines_header.valid?
    end

    # @raise [Rnes::Errors::InvalidInesFormatError]
    def validate!
      unless valid?
        raise ::Rnes::Errors::InvalidInesFormatError
      end
    end
  end
end
