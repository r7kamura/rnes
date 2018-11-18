module Rnes
  class TerminalRenderer
    BRAILLE_BASE_CODE_POINT = 0x2800

    BRAILLE_HEIGHT = 4

    BRAILLE_WIDTH = 2

    BRIGHTNESS_SUM_THRESHOLD = 256

    TEXT_HEIGHT = 61

    TEXT_WIDTH = 128

    ESCAPE_TO_CLEAR_TEXT = "\e[#{TEXT_HEIGHT}A\e[#{TEXT_WIDTH}D".freeze

    def initialize
      @fps = 0
      @previous_fps = 0
    end

    def render(image)
      brailles = convert_image_to_string(image)
      fps_counter = "FPS:#{@previous_fps}"
      puts "#{ESCAPE_TO_CLEAR_TEXT}#{fps_counter}\n#{brailles}"
      second = ::Time.now.sec
      if @second == second
        @fps += 1
      else
        @previous_fps = @fps
        @fps = 0
        @second = second
      end
    end

    private

    # @return [String]
    def convert_image_to_string(image)
      0.step(image.height - 1, BRAILLE_HEIGHT).map do |y|
        0.step(image.width - 1, BRAILLE_WIDTH).map do |x|
          offset = [
            image.read(x: x + 0, y: y + 0),
            image.read(x: x + 0, y: y + 1),
            image.read(x: x + 0, y: y + 2),
            image.read(x: x + 1, y: y + 0),
            image.read(x: x + 1, y: y + 1),
            image.read(x: x + 1, y: y + 2),
            image.read(x: x + 0, y: y + 3),
            image.read(x: x + 1, y: y + 3),
          ].map.with_index do |rgb, i|
            (rgb.sum < BRIGHTNESS_SUM_THRESHOLD ? 0 : 1) << i
          end.reduce(:|)
          (BRAILLE_BASE_CODE_POINT + offset).chr('UTF-8')
        end.join
      end.join("\n")
    end
  end
end
