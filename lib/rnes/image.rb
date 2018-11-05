module Rnes
  class Image
    # @return [Integer]
    attr_reader :height

    # @return [Integer]
    attr_reader :width

    # @param [Integer] height
    # @param [Integer] width
    def initialize(height:, width:)
      @bytes = Array.new(height * width) do
        [0, 0, 0]
      end
      @height = height
      @width = width
    end

    # @param [Integer] x
    # @param [Integer] y
    def read(x:, y:)
      @bytes[@width * y + x]
    end

    # @param [Array<Integer>] rgb
    # @param [Integer] x
    # @param [Integer] y
    def write(value:, x:, y:)
      @bytes[@width * y + x] = value
    end
  end
end
