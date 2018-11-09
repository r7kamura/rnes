RSpec.describe Rnes::Cpu do
  let(:cpu) do
    parts_factory.cpu
  end

  let(:cpu_bus) do
    parts_factory.cpu_bus
  end

  let(:parts_factory) do
    Rnes::PartsFactory.new
  end

  let(:program_rom) do
    Rnes::Rom.new(bytes: program_rom_bytes)
  end

  let(:program_rom_bytes) do
    Array.new(16 * 2**10).map do
      0
    end
  end

  let(:video_ram) do
    parts_factory.video_ram
  end

  let(:working_ram) do
    parts_factory.working_ram
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
      expect(cpu.registers).not_to be_carry
      expect(cpu.registers).not_to be_zero
      expect(cpu.registers).to be_interrupt
      expect(cpu.registers).not_to be_decimal
      expect(cpu.registers).to be_break
      expect(cpu.registers).to be_reserved
      expect(cpu.registers).not_to be_overflow
      expect(cpu.registers).not_to be_negative
      expect(cpu.registers.program_counter).to eq(0x0101)
      expect(program_rom).to have_received(:read).with(0x3FFC)
      expect(program_rom).to have_received(:read).with(0x3FFD)
    end
  end

  describe '#step' do
    subject do
      cpu.step
    end

    before do
      program_rom_bytes[0x0000] = operation_code
      program_rom_bytes[0x3FFC] = program_counter_after_reset & 0xFF
      program_rom_bytes[0x3FFD] = program_counter_after_reset >> 8
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

    # Program ROM state
    #
    # | address | value |
    # | ------- | ----- |
    # | 0x0000  | 0xA9  | <- cpu.cpu_bus.read(0x8000) will return 0xA9 (LDA_IMM)
    # | 0x0001  | 0x01  | <- immediate value
    # | ...     | ...   |
    # | 0x3FFC  | 0x00  |
    # | 0x3FFD  | 0x80  | <- program counter will be 0x8000 after reset
    #
    context 'with LDA_IMM operation' do
      before do
        program_rom_bytes[0x0001] = value
      end

      let(:operation_full_name) do
        :LDA_IMM
      end

      let(:value) do
        0x01
      end

      it 'sets fetched value to accumulator' do
        expect { subject }.to change(cpu.registers, :program_counter).by(2)
        expect(cpu.registers.accumulator).to eq(value)
      end
    end

    # Program ROM state
    #
    # | address | value |
    # | ------- | ----- |
    # | 0x0000  | 0xA5  | <- cpu.cpu_bus.read(0x8000) will return 0xA5 (LDA_ZERO)
    # | 0x0001  | 0x00  | <- value address
    # | ...     | ...   |
    # | 0x3FFC  | 0x00  |
    # | 0x3FFD  | 0x80  | <- program counter will be 0x8000 after reset
    #
    # RAM state
    #
    # | address | value |
    # | ------- | ----- |
    # | 0x0000  | 0x01  | <- value
    context 'with LDA_ZERO operation' do
      before do
        program_rom_bytes[0x0001] = value_address
        working_ram.write(value_address, value)
      end

      let(:operation_full_name) do
        :LDA_ZERO
      end

      let(:value) do
        0x01
      end

      let(:value_address) do
        0x00
      end

      it 'sets value from fetched address to accumulator' do
        expect { subject }.to change(cpu.registers, :program_counter).by(2)
        expect(cpu.registers.accumulator).to eq(value)
      end
    end

    # Program ROM state
    #
    # | address | value |
    # | ------- | ----- |
    # | 0x0000  | 0xB5  |
    # | 0x0001  | 0x00  |
    # | ...     | ...   |
    # | 0x3FFC  | 0x00  |
    # | 0x3FFD  | 0x80  |
    #
    # RAM state
    #
    # | address | value |
    # | ------- | ----- |
    # | 0x0000  | 0x00  |
    # | 0x0001  | 0x01  |
    #
    # CPU registers state
    #
    # | name    | value |
    # | ------- | ----- |
    # | index_x       | 0x01  |
    context 'with LDA_ZEROX operation' do
      before do
        program_rom_bytes[0x0001] = value_base_address
        working_ram.write(value_base_address + index_x, value)
        cpu.registers.index_x = index_x
      end

      let(:operation_full_name) do
        :LDA_ZEROX
      end

      let(:value) do
        0x01
      end

      let(:value_base_address) do
        0x00
      end

      let(:index_x) do
        1
      end

      it 'sets value from fetched address + index_x to accumulator' do
        expect { subject }.to change(cpu.registers, :program_counter).by(2)
        expect(cpu.registers.accumulator).to eq(value)
      end
    end

    context 'with STA_ZERO' do
      before do
        program_rom_bytes[0x0001] = address
        cpu.registers.accumulator = accumulator_value
      end

      let(:accumulator_value) do
        0x01
      end

      let(:address) do
        0x00
      end

      let(:operation_full_name) do
        :STA_ZERO
      end

      it 'sets value from accumulator to fetched address' do
        expect { subject }.to change(cpu.registers, :program_counter).by(2)
        expect(working_ram.read(address)).to eq(accumulator_value)
      end
    end
  end
end
