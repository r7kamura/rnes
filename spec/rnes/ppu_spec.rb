RSpec.describe Rnes::Ppu do
  let(:ppu) do
    described_class.new(bus: ppu_bus)
  end

  let(:ppu_bus) do
    Rnes::PpuBus.new(ram: video_ram)
  end

  let(:video_ram) do
    Rnes::Ram.new
  end

  describe '#tick' do
    subject do
      ppu.tick
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
