RSpec.describe Rnes::Cpu do
  let(:cpu) do
    described_class.new(cpu_bus)
  end

  let(:cpu_bus) do
    Rnes::CpuBus.new(ppu: ppu, ram: ram)
  end

  let(:ppu) do
    Rnes::Ppu.new
  end

  let(:program_rom) do
    Rnes::ProgramRom.new
  end

  let(:ram) do
    Rnes::Ram.new
  end

  describe '#reset' do
    subject do
      cpu_bus.program_rom = program_rom
      cpu.reset
    end

    it 'resets registers and updates program counter' do
      allow(program_rom).to receive(:read).and_return(0x01)
      subject
      expect(cpu.registers).not_to have_carry_bit
      expect(cpu.registers).not_to have_zero_bit
      expect(cpu.registers).to have_interrupt_bit
      expect(cpu.registers).not_to have_decimal_bit
      expect(cpu.registers).to have_break_bit
      expect(cpu.registers).to have_reserved_bit
      expect(cpu.registers).not_to have_overflow_bit
      expect(cpu.registers).not_to have_negative_bit
      expect(cpu.registers.pc).to eq(0x0101)
      expect(program_rom).to have_received(:read).with(0x3FFC)
      expect(program_rom).to have_received(:read).with(0x3FFD)
    end
  end

  describe '#tick' do
    subject do
      cpu.tick
    end

    before do
      cpu_bus.program_rom = program_rom
      allow(cpu).to receive(:fetch_operation_code).and_return(operation_code)
    end

    context 'with unknown operation' do
      let(:operation_code) do
        0xFF
      end

      it 'raises Rnes::Errors::UnknownOperationError' do
        expect { subject }.to raise_error(Rnes::Errors::UnknownOperationError)
      end
    end

    context 'with BRK operation' do
      let(:operation_code) do
        Rnes::Operation::RECORDS.find_index do |record|
          record[:full_name] == :BRK
        end
      end

      it 'sets break bit' do
        subject
        expect(cpu.registers).to have_break_bit
        expect(cpu.registers.pc).to eq(-1)
        expect(cpu.registers.sp).to eq(-3)
      end
    end
  end
end
