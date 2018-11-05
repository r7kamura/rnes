RSpec.describe Rnes::Ppu do
  let(:character_ram) do
    parts_factory.character_ram
  end

  let(:parts_factory) do
    Rnes::PartsFactory.new
  end

  let(:ppu) do
    parts_factory.ppu
  end

  let(:video_ram) do
    parts_factory.video_ram
  end

  describe '#tick' do
    subject do
      ppu.tick
    end

    context 'on cycle 1 on line 0' do
      before do
        # Write dummy background pattern.
        video_ram.write(0x1F01, blue_color_id)

        # Use sprite 1 on tile 0 (cycle 1 on line 0 renders the top line of tile 0).
        video_ram.write(0, sprite_index)

        # Use palette[1] color (blue color in fact) on the top line of sprite 1.
        character_ram.write(16 * sprite_index, sprite_line_low_byte)
        character_ram.write(16 * sprite_index + 1, sprite_line_high_byte)

        ppu.cycle = 1
        ppu.line = 0
      end

      let(:blue_color) do
        [0x0f, 0x0f, 0x65]
      end

      let(:blue_color_id) do
        2
      end

      let(:sprite_index) do
        1
      end

      let(:sprite_line_high_byte) do
        0b00000000
      end

      let(:sprite_line_low_byte) do
        0b11111111
      end

      it 'draws 8 pixels by using palette' do
        subject
        expect(ppu.image.read(x: 0, y: 0)).to eq(blue_color)
      end
    end

    context 'on cycle 340 on line 0' do
      before do
        ppu.cycle = 340
        ppu.line = 0
      end

      it 'updates cycle and line' do
        subject
        expect(ppu.cycle).to eq(0)
        expect(ppu.line).to eq(1)
      end
    end

    context 'on cycle 340 on line 239' do
      before do
        ppu.cycle = 340
        ppu.line = 239
      end

      it 'updates cycle and line, and sets in_v_blank bit' do
        subject
        expect(ppu.cycle).to eq(0)
        expect(ppu.line).to eq(240)
        expect(ppu.registers).to have_in_v_blank_bit
      end
    end

    context 'on cycle 340 on line 261' do
      before do
        ppu.cycle = 340
        ppu.line = 261
        ppu.registers.toggle_in_v_blank_bit(true)
        ppu.registers.toggle_sprite_hit_bit(true)
        allow(ppu).to receive(:render_image)
      end

      it 'updates cycle and line, render image, and unsets some bits' do
        subject
        expect(ppu.cycle).to eq(0)
        expect(ppu.line).to eq(0)
        expect(ppu).to have_received(:render_image)
        expect(ppu.registers).not_to have_in_v_blank_bit
        expect(ppu.registers).not_to have_sprite_hit_bit
      end
    end
  end
end
