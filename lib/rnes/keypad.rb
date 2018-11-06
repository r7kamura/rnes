module Rnes
  class Keypad
    KEY_MAP = {
      '.' => 0,
      ',' => 1,
      'n' => 2,
      'm' => 3,
      'w' => 4,
      's' => 5,
      'a' => 6,
      'd' => 7,
    }.freeze

    def initialize
      @buffer = 0
      @copy = 0
      @index = 0
    end

    def check
      character = ::STDIN.read_nonblock(1)
      index = KEY_MAP[character]
      if index
        @buffer |= 1 << index
      end
    rescue ::EOFError
      # Rescue on no STDIN environment (e.g. CircleCI).
    rescue ::IO::WaitReadable
      # Rescue on no data in STDIN buffer.
    end

    # @return [Integer]
    def read
      value = @copy[@index]
      @index = (@index + 1) % 0x10
      value
    end

    # @param [Integer] value
    def write(value)
      if value[0] == 1
        @set = true
      elsif @set
        @set = false
        @copy = @buffer
        @buffer = 0
        @index = 0
      end
    end
  end
end
