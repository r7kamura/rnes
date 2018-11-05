RSpec.describe Rnes::RomLoader do
  let(:rom_bytes) do
    ines_header_bytes + trainer_bytes + program_rom_bytes + character_rom_bytes
  end

  let(:rom_loader) do
    described_class.new(rom_bytes)
  end

  shared_context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM' do
    let(:character_rom_bytes) do
      []
    end

    let(:ines_header_bytes) do
      [
        0x4E,
        0x45,
        0x53,
        0x1A,
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
        0x00,
      ]
    end

    let(:program_rom_bytes) do
      []
    end

    let(:trainer_bytes) do
      []
    end
  end

  shared_context 'with invalid iNES header' do
    let(:rom_bytes) do
      []
    end
  end

  shared_context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM' do
    let(:character_rom_bytes) do
      Array.new(8 * 2**10).map do
        0x03
      end
    end

    let(:ines_header_bytes) do
      [
        0x4E,
        0x45,
        0x53,
        0x1A,
        0x01,
        0x01,
        0b00000100,
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
        0x02
      end
    end

    let(:trainer_bytes) do
      Array.new(512).map do
        0x01
      end
    end
  end

  shared_examples 'raises Rnes::Errors::InvalidInesFormatError' do
    it 'raises Rnes::Errors::InvalidInesFormatError' do
      expect { subject }.to raise_error(Rnes::Errors::InvalidInesFormatError)
    end
  end

  shared_examples 'returns ROM including expected bytes' do
    it 'returns character ROM' do
      valid = bytes.length.times.map.all? do |index|
        subject.read(index) == bytes[index]
      end
      expect(valid).to eq(true)
    end
  end

  describe '#character_rom' do
    subject do
      rom_loader.character_rom
    end

    let(:bytes) do
      character_rom_bytes
    end

    context 'with invalid iNES header' do
      include_context 'with invalid iNES header'

      include_examples 'raises Rnes::Errors::InvalidInesFormatError'
    end

    context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM' do
      include_context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM'

      include_examples 'returns ROM including expected bytes'
    end

    context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM' do
      include_context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM'

      include_examples 'returns ROM including expected bytes'
    end
  end

  describe '#program_rom' do
    subject do
      rom_loader.program_rom
    end

    let(:bytes) do
      program_rom_bytes
    end

    context 'with invalid iNES header' do
      include_context 'with invalid iNES header'

      include_examples 'raises Rnes::Errors::InvalidInesFormatError'
    end

    context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM' do
      include_context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM'

      include_examples 'returns ROM including expected bytes'
    end

    context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM' do
      include_context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM'

      include_examples 'returns ROM including expected bytes'
    end
  end

  describe '#trainer_rom' do
    subject do
      rom_loader.trainer_rom
    end

    let(:bytes) do
      trainer_bytes
    end

    context 'with invalid iNES header' do
      include_context 'with invalid iNES header'

      include_examples 'raises Rnes::Errors::InvalidInesFormatError'
    end

    context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM' do
      include_context 'with 0 byte trainer, 0 byte program ROM, and 0 byte character ROM'

      include_examples 'returns ROM including expected bytes'
    end

    context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM' do
      include_context 'with 512 byte trainer, 16 byte program ROM, and 8 byte character ROM'

      include_examples 'returns ROM including expected bytes'
    end
  end
end
