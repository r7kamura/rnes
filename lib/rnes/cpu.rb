require 'rnes/cpu_bus'
require 'rnes/cpu_registers'
require 'rnes/errors'
require 'rnes/operation'

module Rnes
  class Cpu
    # @return [Rnes::CpuRegisters]
    attr_reader :registers

    # @param [Rnes::CpuBus] bus
    def initialize(bus:)
      @branched = false
      @bus = bus
      @registers = ::Rnes::CpuRegisters.new
    end

    def reset
      @registers.reset
      @registers.program_counter = read_word(0xFFFC)
    end

    # @todo Cycle calculation by using Rnes::Operation#cycle.
    def tick
      operation = fetch_operation
      operand = fetch_operand(operation)
      case operation.name
      when :ADC
        execute_operation_adc(operand)
      when :AND
        execute_operation_and(operand)
      when :ASL
        execute_operation_asl(operand, addressing_mode: operation.addressing_mode)
      when :BCC
        execute_operation_bcc(operand)
      when :BCS
        execute_operation_bcs(operand)
      when :BEQ
        execute_operation_beq(operand)
      when :BIT
        execute_operation_bit(operand)
      when :BMI
        execute_operation_bmi(operand)
      when :BNE
        execute_operation_bne(operand)
      when :BPL
        execute_operation_bpl(operand)
      when :BRK
        execute_operation_brk(operand)
      when :BVC
        execute_operation_bvc(operand)
      when :BVS
        execute_operation_bvs(operand)
      when :CLC
        execute_operation_clc(operand)
      when :CLD
        execute_operation_cld(operand)
      when :CLI
        execute_operation_cli(operand)
      when :CLV
        execute_operation_clv(operand)
      when :CMP
        execute_operation_cmp(operand)
      when :CPX
        execute_operation_cpx(operand)
      when :CPY
        execute_operation_cpy(operand)
      when :DCP
        execute_operation_dcp(operand)
      when :DEC
        execute_operation_dec(operand)
      when :DEX
        execute_operation_dex(operand)
      when :DEY
        execute_operation_dey(operand)
      when :EOR
        execute_operation_eor(operand)
      when :INC
        execute_operation_inc(operand)
      when :INX
        execute_operation_inx(operand)
      when :INY
        execute_operation_iny(operand)
      when :ISB
        execute_operation_isb(operand)
      when :JMP
        execute_operation_jmp(operand)
      when :JSR
        execute_operation_jsr(operand)
      when :LAX
        execute_operation_lax(operand)
      when :LDA
        execute_operation_lda(operand)
      when :LDX
        execute_operation_ldx(operand)
      when :LDY
        execute_operation_ldy(operand)
      when :LSR
        execute_operation_lsr(operand, addressing_mode: operation.addressing_mode)
      when :NOP
        execute_operation_nop(operand)
      when :NOPD
        execute_operation_nopd(operand)
      when :NOPI
        execute_operation_nopi(operand)
      when :ORA
        execute_operation_ora(operand)
      when :PHA
        execute_operation_pha(operand)
      when :PHP
        execute_operation_php(operand)
      when :PLA
        execute_operation_pla(operand)
      when :PLP
        execute_operation_plp(operand)
      when :RLA
        execute_operation_rla(operand)
      when :ROL
        execute_operation_rol(operand)
      when :ROR
        execute_operation_ror(operand)
      when :RRA
        execute_operation_rra(operand)
      when :RTI
        execute_operation_rti(operand)
      when :RTS
        execute_operation_rts(operand)
      when :SAX
        execute_operation_sax(operand)
      when :SBC
        execute_operation_sbc(operand)
      when :SEC
        execute_operation_sec(operand)
      when :SED
        execute_operation_sed(operand)
      when :SEI
        execute_operation_sei(operand)
      when :SLO
        execute_operation_slo(operand)
      when :SRE
        execute_operation_sre(operand)
      when :STA
        execute_operation_sta(operand)
      when :STX
        execute_operation_stx(operand)
      when :STY
        execute_operation_sty(operand)
      when :TAX
        execute_operation_tax(operand)
      when :TAY
        execute_operation_tay(operand)
      when :TSX
        execute_operation_tsx(operand)
      when :TXA
        execute_operation_txa(operand)
      when :TXS
        execute_operation_txs(operand)
      when :TYA
        execute_operation_tya(operand)
      else
        raise ::Rnes::Errors::UnknownOperationError, "Unknown operation: #{operation.name}"
      end
      @branched = false
    end

    private

    # @param [Integer] address
    def branch(address)
      @branched = true
      registers.program_counter = address
    end

    # @note ADC means "ADD with Carry".
    # @param [Integer] operand
    def execute_operation_adc(operand)
      result = operand + registers.accumulator + registers.carry_bit
      registers.carry = result > 0xFF
      registers.negative = result[7] == 1
      registers.overflow = (registers.accumulator ^ operand)[7].zero? && !(registers.accumulator ^ result)[7].zero?
      registers.zero = result.zero?
      registers.accumulator = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_and(operand)
      result = operand & registers.accumulator
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result
    end

    # @param [Symbol] addressing_mode
    # @param [Integer] operand
    def execute_operation_asl(operand, addressing_mode:)
      if addressing_mode == :accumulator
        value = registers.accumulator
        result = (value << 1) && 0xFF
        registers.carry = value[7] == 1
        registers.negative = result[7] == 1
        registers.zero = result.zero?
        registers.accumulator = result
      else
        value = read(operand)
        result = (value << 1) && 0xFF
        registers.carry = value[7] == 1
        registers.negative = result[7] == 1
        registers.zero = result.zero?
        write(operand, result)
      end
    end

    # @param [Integer] operand
    def execute_operation_bcc(operand)
      unless registers.carry?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bcs(operand)
      if registers.carry?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_beq(operand)
      if registers.zero?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bit(operand)
      result = read(operand)
      registers.overflow = result[6] == 1
      registers.negative = result[7] == 1
      registers.zero = (registers.accumulator & result).zero?
    end

    # @param [Integer] operand
    def execute_operation_bmi(_operand)
      unless registers.negative?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bne(operand)
      unless registers.zero?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bpl(operand)
      unless registers.negative?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_brk(_operand)
      registers.break = true
      registers.program_counter += 1
      push_word(registers.program_counter)
      push(registers.status)
      unless registers.interrupt?
        registers.interrupt = true
        registers.program_counter = read_word(0xFFFE)
      end
      registers.program_counter -= 1
    end

    # @param [Integer] operand
    def execute_operation_bvc(operand)
      unless registers.overflow?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bvs(operand)
      if registers.overflow?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_clc(_operand)
      registers.carry = false
    end

    # @param [Integer] operand
    def execute_operation_cld(_operand)
      registers.decimal = false
    end

    # @param [Integer] operand
    def execute_operation_cli(_operand)
      registers.interrupt = false
    end

    # @param [Integer] operand
    def execute_operation_clv(_operand)
      registers.overflow = false
    end

    # @param [Integer] operand
    def execute_operation_cmp(operand)
      result = registers.accumulator - operand
      registers.carry = result >= 0
      registers.negative = result[7] == 1
      registers.zero = (result & 0xFF).zero?
    end

    # @param [Integer] operand
    def execute_operation_cpx(operand)
      result = registers.index_x - operand
      registers.carry = result >= 0
      registers.negative = result[7] == 1
      registers.zero = (result & 0xFF).zero?
    end

    # @param [Integer] operand
    def execute_operation_cpy(operand)
      result = registers.index_y - operand
      registers.carry = result >= 0
      registers.negative = result[7] == 1
      registers.zero = (result & 0xFF).zero?
    end

    # @param [Integer] operand
    def execute_operation_dcp(operand)
      result = (read(operand) - 1) & 0xFF
      sub_result = (registers.accumulator - result) & 0x1FF
      registers.negative = sub_result[7] == 1
      registers.zero = sub_result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_dec(operand)
      result = (read(operand) - 1) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_dex(_operand)
      result = (registers.index_x - 1) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_dey(_operand)
      result = (registers.index_y - 1) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.index_y = result
    end

    # @param [Integer] operand
    def execute_operation_eor(operand)
      result = (operand ^ registers.accumulator) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_inc(operand)
      result = (read(operand) + 1) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_inx(_operand)
      result = (registers.index_x + 1) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_iny(_operand)
      result = (registers.index_y + 1) & 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.index_y = result
    end

    # @param [Integer] operand
    def execute_operation_isb(_operand)
      value = (read(operand) + 1) & 0xFF
      result = (~value & 0xFF) + registers.accumulator + registers.carry
      registers.overflow = (registers.accumulator ^ value)[7].zero? && !(registers.accumulator ^ result)[7].zero?
      registers.carry = result > 0xFF
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result & 0xFF
      write(address, value)
    end

    # @param [Integer] operand
    def execute_operation_jmp(operand)
      registers.program_counter = operand
    end

    # @param [Integer] operand
    def execute_operation_jsr(operand)
      push_word(registers.program_counter - 1)
      registers.program_counter = operand
    end

    # @param [Integer] operand
    def execute_operation_lax(operand)
      result = read(operand)
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result
      registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_lda(operand)
      registers.negative = operand[7] == 1
      registers.zero = operand.zero?
      registers.accumulator = operand
    end

    # @param [Integer] operand
    def execute_operation_ldx(operand)
      registers.negative = operand[7] == 1
      registers.zero = operand.zero?
      registers.index_x = operand
    end

    # @param [Integer] operand
    def execute_operation_ldy(operand)
      registers.negative = operand[7] == 1
      registers.zero = operand.zero?
      registers.index_y = operand
    end

    # @param [Symbol] addressing_mode
    # @param [Integer] operand
    def execute_operation_lsr(operand, addressing_mode:)
      if addressing_mode == :accumulator
        value = registers.accumulator
        result = value >> 1
        registers.carry = value[0] == 1
        registers.zero = result.zero?
        registers.accumulator = result
      else
        value = read(operand)
        result = value >> 1
        registers.carry = value[0] == 1
        registers.zero = result.zero?
        write(operand, result)
      end
      registers.negative = false
    end

    # @param [Integer] operand
    def execute_operation_nop(operand)
    end

    # @param [Integer] operand
    def execute_operation_nopd(_operand)
      registers.program_counter += 1
    end

    # @param [Integer] operand
    def execute_operation_nopi(_operand)
      registers.program_counter += 2
    end

    # @param [Integer] operand
    def execute_operation_ora(operand)
      result = registers.accumulator | operand
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_pha(_operand)
      push(registers.accumulator)
    end

    # @param [Integer] operand
    def execute_operation_php(_operand)
      registers.break = true
      push(registers.status)
    end

    # @param [Integer] operand
    def execute_operation_pla(_operand)
      result = pop
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_plp(_operand)
      registers.status = pop
      registers.reserved = true
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_rla(_operand)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_rol(_operand)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_ror(_operand)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_rra(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_rti(_operand)
      registers.status = pop
      registers.program_counter = pop_word
      registers.reserved = true
    end

    # @param [Integer] operand
    def execute_operation_rts(_operand)
      registers.program_counter = pop_word
      registers.program_counter += 1
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_sax(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_sbc(operand)
      result = registers.accumulator - operand - 1 + registers.carry_bit
      registers.overflow = ((registers.accumulator ^ result) & 0x80 != 0 && ((registers.accumulator ^ operand) & 0x80) != 0)
      registers.carry = result >= 0
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_sec(_operand)
      registers.carry = true
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_sed(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_sei(_operand)
      registers.interrupt = true
    end

    # @param [Integer] operand
    def execute_operation_slo(operand)
      value = read(operand)
      registers.carry = value[7] == 1
      result = (value << 1) & 0xFF
      registers.accumulator |= result
      registers.negative = registers.accumulator[7] == 1
      registers.zero = registers.accumulator.zero?
      write(address, result)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_sre(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_sta(operand)
      write(operand, registers.accumulator)
    end

    # @param [Integer] operand
    def execute_operation_stx(operand)
      write(operand, registers.index_x)
    end

    # @param [Integer] operand
    def execute_operation_sty(operand)
      write(operand, registers.index_y)
    end

    # @param [Integer] operand
    def execute_operation_tax(_operand)
      result = registers.accumulator
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_tay(_operand)
      result = registers.accumulator
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.index_y = result
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_tsx(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_txa(_operand)
      result = registers.index_x
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_txs(_operand)
      registers.stack_pointer = registers.index_x + 0x100
    end

    # @param [Integer] operand
    def execute_operation_tya(_operand)
      result = registers.index_y
      registers.negative = result[7] == 1
      registers.zero = result.zero?
      registers.accumulator = result
    end

    # @return [Integer]
    def fetch
      address = @registers.program_counter
      value = read(address)
      @registers.program_counter += 1
      value
    end

    # @param [Rnes::Operation]
    def fetch_operand(operation)
      value = fetch_value_by_addressing_mode(operation.addressing_mode)
      if operation.unimmediate?
        read(value)
      else
        value
      end
    end

    # @return [Rnes::Operation]
    def fetch_operation
      operation_code = fetch
      ::Rnes::Operation.build(operation_code)
    end

    # @param [Symbol] addressing_mode
    # @return [Integer]
    def fetch_value_by_addressing_mode(addressing_mode)
      case addressing_mode
      when :absolute
        fetch_value_by_addressing_mode_absolute
      when :absolute_x
        fetch_value_by_addressing_mode_absolute_x
      when :absolute_y
        fetch_value_by_addressing_mode_absolute_y
      when :accumulator
        fetch_value_by_addressing_mode_accumulator
      when :immediate
        fetch_value_by_addressing_mode_immediate
      when :implied
        fetch_value_by_addressing_mode_implied
      when :indirect_absolute
        fetch_value_by_addressing_mode_indirect_absolute
      when :post_indexed_indirect
        fetch_value_by_addressing_mode_post_indexed_indirect
      when :pre_indexed_indirect
        fetch_value_by_addressing_mode_pre_indexed_indirect
      when :relative
        fetch_value_by_addressing_mode_relative
      when :zero_page
        fetch_value_by_addressing_mode_zero_page
      when :zero_page_x
        fetch_value_by_addressing_mode_zero_page_x
      when :zero_page_y
        fetch_value_by_addressing_mode_zero_page_y
      else
        raise ::Rnes::Errors::UnknownAddressingModeError, "Unknown addressing mode: #{addressing_mode}"
      end
    end

    # @param [Symbol] addressing_mode
    # @return [Integer]
    def fetch_value_by_addressing_mode_with_optional_read(addressing_mode)
      value = fetch_value_by_addressing_mode(addressing_mode)
      value = read(value) if addressing_mode != :immediate
      value
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_absolute
      fetch_word
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_absolute_x
      (fetch_word + registers.index_x) & 0xFFFF
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_absolute_y
      (fetch_word + registers.index_y) & 0xFFFF
    end

    # @return [nil]
    def fetch_value_by_addressing_mode_accumulator
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_immediate
      fetch
    end

    # @return [nil]
    def fetch_value_by_addressing_mode_implied
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_indirect_absolute
      read_word(fetch_word)
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_pre_indexed_indirect
      read_word((fetch + registers.index_x) & 0xFF)
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_post_indexed_indirect
      (read_word(fetch) + registers.index_y) & 0xFF
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_relative
      int8 = fetch
      offset = int8 > 0x80 ? int8 - 256 : int8
      registers.program_counter + offset
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page
      fetch
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page_x
      (fetch + registers.index_x) & 0xFF
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page_y
      (fetch + registers.index_y) & 0xFF
    end

    # @return [Integer]
    def fetch_word
      fetch | (fetch << 8)
    end

    # @return [Integer]
    def pop
      registers.stack_pointer += 1
      read(registers.stack_pointer & 0xFF | 0x100)
    end

    # @return [Integer]
    def pop_word
      pop | pop << 8
    end

    # @param [Integer] value
    def push(value)
      write(registers.stack_pointer | 0x100, value)
      registers.stack_pointer -= 1
    end

    # @param [Integer] value
    def push_word(value)
      push(value >> 8)
      push(value & 0xFF)
    end

    # @param [Integer] address
    # @return [Integer]
    def read(address)
      @bus.read(address)
    end

    # @param [Integer] address
    # @return [Integer]
    def read_word(address)
      read(address) | read((address + 1) & 0xFFFF) << 8
    end

    # @param [Integer] address
    # @param [Integer] value
    def write(address, value)
      @bus.write(address, value)
    end
  end
end
