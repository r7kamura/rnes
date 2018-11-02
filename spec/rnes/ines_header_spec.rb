RSpec.describe Rnes::InesHeader do
  let(:ines_header) do
    described_class.new(rom_bytes)
  end

  describe '#valid?' do
    subject do
      ines_header.valid?
    end

    context 'with invalid bytes' do
      let(:rom_bytes) do
        []
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'with leading NES + 0x1A bytes' do
      let(:rom_bytes) do
        'NES'.chars.map(&:ord) + [0x1A]
      end

      it 'returns true' do
        is_expected.to eq(true)
      end
    end
  end
end
