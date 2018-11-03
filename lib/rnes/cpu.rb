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
      @bus = bus
      @registers = ::Rnes::CpuRegisters.new
    end

    def reset
      @registers.reset
      @registers.pc = read_word(0xFFFC)
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
        execute_operation_asl(operand)
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
        execute_operation_lsr(operand)
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
    end

    private

    # @param [Integer] value
    def adjust_carry_bit(value)
      flag = value > 0xFF
      registers.toggle_carry_bit(flag)
    end

    # @param [Integer] value
    def adjust_negative_bit(value)
      flag = value >= 0x80
      registers.toggle_negative_bit(flag)
    end

    # @param [Integer] value
    def adjust_overflow_bit(value)
      flag = value >= 0xFF || value < -0xFF
      registers.toggle_overflow_bit(flag)
    end

    # @param [Integer] value
    def adjust_zero_bit(value)
      flag = value.zero?
      registers.toggle_zero_bit(flag)
    end

    # @param [Integer] address
    def branch(address)
      registers.pc = address
    end

    # @param [Integer] operand
    def execute_operation_adc(operand)
      result = operand + registers.x + registers.carry_bit
      adjust_carry_bit(result)
      adjust_negative_bit(result)
      adjust_overflow_bit(result)
      adjust_zero_bit(result)
      registers.a = result & 0xFF
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_and(_operand)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_asl(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_bcc(operand)
      unless registers.has_carry_bit?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bcs(operand)
      if registers.has_carry_bit?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_beq(operand)
      if registers.has_zero_bit?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bit(operand)
      result = read(operand)
      registers.toggle_overflow_bit(result[6] != 0)
      adjust_negative_bit(result)
      adjust_zero_bit(registers.a & result)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_bmi(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_bne(operand)
      unless registers.has_zero_bit?
        registers.pc = operand
      end
    end

    # @param [Integer] operand
    def execute_operation_bpl(operand)
      unless registers.has_negative_bit?
        registers.pc = operand
      end
    end

    # @param [Integer] operand
    def execute_operation_brk(_operand)
      registers.toggle_break_bit(true)
      push_word(registers.pc)
      push(registers.p)
      unless registers.has_interrupt_bit?
        registers.toggle_interrupt_bit(true)
        registers.pc = read_word(0xFFFE)
      end
      registers.pc -= 1
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_bvc(_operand)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_bvs(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_clc(_operand)
      registers.toggle_carry_bit(true)
    end

    # @param [Integer] operand
    def execute_operation_cld(_operand)
      registers.toggle_decimal_bit(false)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_cli(_operand)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_clv(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_cmp(operand)
      result = registers.a - operand
      registers.toggle_carry_bit(result >= 0)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
    end

    # @param [Integer] operand
    def execute_operation_cpx(operand)
      result = registers.x - operand
      registers.toggle_carry_bit(result >= 0)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
    end

    # @param [Integer] operand
    def execute_operation_cpy(operand)
      result = registers.y - operand
      registers.toggle_carry_bit(result >= 0)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_dcp(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_dec(operand)
      result = read(operand) - 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_dex(_operand)
      result = registers.x - 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.x = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_dey(_operand)
      result = registers.y - 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.y = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_eor(operand)
      result = operand ^ registers.a
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_inc(operand)
      result = read(operand) + 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      write(operand, result & 0xFF)
    end

    # @param [Integer] operand
    def execute_operation_inx(_operand)
      result = registers.x + 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.x = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_iny(_operand)
      result = registers.y + 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.y = result & 0xFF
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_isb(_operand)
      raise NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_jmp(operand)
      registers.pc = operand
    end

    # @param [Integer] operand
    def execute_operation_jsr(operand)
      push_word(registers.pc - 1)
      registers.pc = operand
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_lax(_operand)
      raise NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_lda(operand)
      adjust_negative_bit(operand)
      adjust_zero_bit(operand)
      registers.a = operand
    end

    # @param [Integer] operand
    def execute_operation_ldx(operand)
      adjust_negative_bit(operand)
      adjust_zero_bit(operand)
      registers.x = operand
    end

    # @param [Integer] operand
    def execute_operation_ldy(operand)
      adjust_negative_bit(operand)
      adjust_zero_bit(operand)
      registers.y = operand
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_lsr(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_nop(operand)
    end

    # @param [Integer] operand
    def execute_operation_nopd(_operand)
      registers.pc += 1
    end

    # @param [Integer] operand
    def execute_operation_nopi(_operand)
      registers.pc += 2
    end

    # @param [Integer] operand
    def execute_operation_ora(operand)
      result = registers.a | operand
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result % 0xFF
    end

    # @param [Integer] operand
    def execute_operation_pha(_operand)
      push(registers.a)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_php(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_pla(_operand)
      result = pop
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_plp(_operand)
      raise ::NotImplementedError
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
      registers.p = pop
      registers.pc = pop_word
      registers.toggle_reserved_bit(true)
    end

    # @param [Integer] operand
    def execute_operation_rts(_operand)
      registers.pc = pop_word
      registers.pc += 1
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_sax(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_sbc(operand)
      result = registers.a - operand - 1 + registers.carry_bit
      registers.toggle_overflow_bit((registers.a ^ result) & 0x80 != 0 && ((registers.a ^ operand) & 0x80) != 0)
      registers.toggle_carry_bit(result >= 0)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_sec(_operand)
      registers.toggle_carry_bit(true)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_sed(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_sei(_operand)
      registers.toggle_interrupt_bit(true)
    end

    # @param [Integer] operand
    def execute_operation_slo(operand)
      value = read(operand)
      adjust_carry_bit(value)
      result = (value << 1) & 0xFF
      registers.a |= result
      adjust_negative_bit(registers.a)
      adjust_zero_bit(registers.a)
      write(address, result)
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_sre(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_sta(operand)
      write(operand, registers.a)
    end

    # @param [Integer] operand
    def execute_operation_stx(operand)
      write(operand, registers.x)
    end

    # @param [Integer] operand
    def execute_operation_sty(operand)
      write(operand, registers.y)
    end

    # @param [Integer] operand
    def execute_operation_tax(_operand)
      result = registers.a
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.x = result
    end

    # @param [Integer] operand
    def execute_operation_tay(_operand)
      result = registers.a
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.y = result
    end

    # @todo
    # @param [Integer] operand
    def execute_operation_tsx(_operand)
      raise ::NotImplementedError
    end

    # @param [Integer] operand
    def execute_operation_txa(_operand)
      result = registers.x
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result
    end

    # @param [Integer] operand
    def execute_operation_txs(_operand)
      registers.sp = registers.x + 0x100
    end

    # @param [Integer] operand
    def execute_operation_tya(_operand)
      result = registers.y
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result
    end

    # @return [Integer]
    def fetch
      address = @registers.pc
      value = read(address)
      @registers.pc += 1
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
      (fetch_word + registers.x) & 0xFFFF
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_absolute_y
      (fetch_word + registers.y) & 0xFFFF
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
      read_word((fetch + registers.x) & 0xFF)
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_post_indexed_indirect
      (read_word(fetch) + registers.y) & 0xFF
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_relative
      int8 = fetch
      offset = int8 > 0x80 ? int8 - 256 : int8
      registers.pc + offset
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page
      fetch
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page_x
      (fetch + registers.x) & 0xFF
    end

    # @return [Integer]
    def fetch_value_by_addressing_mode_zero_page_y
      (fetch + registers.y) & 0xFF
    end

    # @return [Integer]
    def fetch_word
      fetch | (fetch << 8)
    end

    # @return [Integer]
    def pop
      registers.sp += 1
      read(registers.sp & 0xFF | 0x100)
    end

    # @return [Integer]
    def pop_word
      pop | pop << 8
    end

    # @param [Integer] value
    def push(value)
      write(registers.sp | 0x100, value)
      registers.sp -= 1
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
