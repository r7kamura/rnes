RSpec.describe Rnes::Emulator do
  let(:emulator) do
    described_class.new
  end

  let(:program_rom_bytes) do
    Array.new(16 * 2 ** 10).map do
      0
    end
  end

  let(:rom_bytes) do
    [
      0x4E,
      0x45,
      0x53,
      0x1A,
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
      0x00,
    ] + program_rom_bytes
  end

  describe '#load_rom' do
    subject do
      emulator.load_rom(rom_bytes)
    end

    it 'sets loaded data to CPU bus and PPU bus' do
      subject
      expect(emulator.cpu_bus.program_rom).to be_a(Rnes::ProgramRom)
      expect(emulator.ppu_bus.character_rom).to be_a(Rnes::CharacterRom)
    end
  end

  describe '#tick' do
    subject do
      emulator.tick
    end

    before do
      emulator.load_rom(rom_bytes)
    end

    it 'ticks CPU and PPU' do
      expect { subject }.not_to raise_error
    end
  end
end
