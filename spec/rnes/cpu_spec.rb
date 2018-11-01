RSpec.describe Rnes::Cpu do
  let(:cpu) do
    described_class.new(cpu_bus)
  end

  let(:cpu_bus) do
    Rnes::CpuBus.new
  end

  describe '#fetch_operation' do
    subject do
      cpu.fetch_operation
    end

    before do
      cpu.reset
    end

    it 'fetches operation from where program counter points to' do
      is_expected.to be_a(Rnes::Operation)
    end

    it 'increments program counter' do
      expect { subject }.to change(cpu.registers, :pc).by(1)
    end
  end

  describe '#reset' do
    subject do
      cpu.reset
    end

    it 'resets registers status and updates program counter' do
      subject
      expect(cpu.registers).not_to have_carry_bit
      expect(cpu.registers).not_to have_zero_bit
      expect(cpu.registers).to have_interrupt_bit
      expect(cpu.registers).not_to have_decimal_bit
      expect(cpu.registers).to have_break_bit
      expect(cpu.registers).to have_reserved_bit
      expect(cpu.registers).not_to have_overflow_bit
      expect(cpu.registers).not_to have_negative_bit
    end

    it 'reads address from 0xFFFC and asssigns it to program counter ' do
      dummy_byte = 0x01
      allow(cpu).to receive(:read).and_return(dummy_byte)
      subject
      expect(cpu.registers.pc).to eq(0x0101)
      expect(cpu).to have_received(:read).with(0xFFFC)
    end
  end
end
