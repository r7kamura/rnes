RSpec.describe Rnes::Cpu do
  let(:cpu) do
    described_class.new(bus: cpu_bus)
  end

  let(:cpu_bus) do
    Rnes::CpuBus.new(ppu: ppu, ram: ram)
  end

  let(:ppu) do
    Rnes::Ppu.new(bus: ppu_bus)
  end

  let(:ppu_bus) do
    Rnes::PpuBus.new
  end

  let(:program_rom) do
    Rnes::ProgramRom.new(program_rom_bytes)
  end

  let(:program_rom_bytes) do
    Array.new(16 * 2**10).map do
      0
    end
  end

  let(:ram) do
    Rnes::Ram.new
  end

  describe '#reset' do
    subject do
      cpu.reset
    end

    before do
      cpu_bus.program_rom = program_rom
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
      program_rom.write(0x0000, operation_code)
      program_rom.write(0x3FFC, program_counter_after_reset & 0xFF)
      program_rom.write(0x3FFD, program_counter_after_reset >> 8)
      cpu_bus.program_rom = program_rom
      cpu.reset
    end

    let(:program_counter_after_reset) do
      0x8000
    end

    let(:operation_code) do
      Rnes::Operation::RECORDS.find_index do |record|
        record[:full_name] == operation_full_name
      end
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
      let(:operation_full_name) do
        :BRK
      end

      it 'sets break bit' do
        subject
        expect(cpu.registers).to have_break_bit
        expect(cpu.registers.pc).to eq(program_counter_after_reset)
      end
    end

    # Program ROM
    #
    # | address | value |
    # | ------- | ----- |
    # | 0x0000  | 0xA9  | <- cpu.cpu_bus.read(0x8000) will return 0xA9 (LDA_IMM)
    # | ...     | ...   |
    # | 0x3FFC  | 0x00  |
    # | 0x3FFD  | 0x80  | <- program counter will be 0x8000 after reset
    #
    context 'with LDA_IMM operation' do
      let(:operation_full_name) do
        :LDA_IMM
      end

      it 'fetches value and sets it to accumulator' do
        expect { subject }.to change(cpu.registers, :pc).by(2)
        expect(cpu.registers.a).to eq(0)
      end
    end
  end
end
