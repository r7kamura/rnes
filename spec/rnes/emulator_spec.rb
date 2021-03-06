RSpec.describe Rnes::Emulator do
  let(:character_rom_bytes) do
    Array.new(8 * 2**10).map do
      0
    end
  end

  let(:emulator) do
    described_class.new
  end

  let(:ines_header_bytes) do
    [
      0x4E,
      0x45,
      0x53,
      0x1A,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]
  end

  let(:program_rom_bytes) do
    Array.new(16 * 2**10).map do
      0
    end
  end

  let(:rom_bytes) do
    ines_header_bytes + program_rom_bytes + character_rom_bytes
  end

  describe '#step' do
    subject do
      emulator.step
    end

    before do
      emulator.load_rom(rom_bytes)
    end

    it 'steps CPU and PPU' do
      expect { subject }.not_to raise_error
    end
  end
end
