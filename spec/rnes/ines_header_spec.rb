RSpec.describe Rnes::InesHeader do
  let(:ines_header) do
    described_class.new(data)
  end

  describe '#valid?' do
    subject do
      ines_header.valid?
    end

    context 'with leading NES + 0x1A bytes' do
      let(:data) do
        'NES'.chars.map(&:ord) + [0x1A]
      end

      it 'returns true' do
        is_expected.to eq(true)
      end
    end
  end
end
