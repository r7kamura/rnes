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
      execute_operation(operation)
    end

    private

    # @param [Integer] value
    def adjust_carry_bit(value)
      flag = value > 0xFF
      registers.toggle_carry_bit(flag)
    end

    # @param [Integer] value
    def adjust_negative_bit(value)
      flag = value.negative?
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

    # @param [Rnes::Operation] operation
    def execute_operation(operation)
      case operation.name
      when :ADC
        execute_operation_adc(operation)
      when :AND
        execute_operation_and(operation)
      when :ASL
        execute_operation_asl(operation)
      when :BCC
        execute_operation_bcc(operation)
      when :BCS
        execute_operation_bcs(operation)
      when :BEQ
        execute_operation_beq(operation)
      when :BIT
        execute_operation_bit(operation)
      when :BMI
        execute_operation_bmi(operation)
      when :BNE
        execute_operation_bne(operation)
      when :BPL
        execute_operation_bpl(operation)
      when :BRK
        execute_operation_brk(operation)
      when :BVC
        execute_operation_bvc(operation)
      when :BVS
        execute_operation_bvs(operation)
      when :CLC
        execute_operation_clc(operation)
      when :CLD
        execute_operation_cld(operation)
      when :CLI
        execute_operation_cli(operation)
      when :CLV
        execute_operation_clv(operation)
      when :CMP
        execute_operation_cmp(operation)
      when :CPX
        execute_operation_cpx(operation)
      when :CPY
        execute_operation_cpy(operation)
      when :DCP
        execute_operation_dcp(operation)
      when :DEC
        execute_operation_dec(operation)
      when :DEX
        execute_operation_dex(operation)
      when :DEY
        execute_operation_dey(operation)
      when :EOR
        execute_operation_eor(operation)
      when :INC
        execute_operation_inc(operation)
      when :INX
        execute_operation_inx(operation)
      when :INY
        execute_operation_iny(operation)
      when :ISB
        execute_operation_isb(operation)
      when :JMP
        execute_operation_jmp(operation)
      when :JSR
        execute_operation_jsr(operation)
      when :LAX
        execute_operation_lax(operation)
      when :LDA
        execute_operation_lda(operation)
      when :LDX
        execute_operation_ldx(operation)
      when :LDY
        execute_operation_ldy(operation)
      when :LSR
        execute_operation_lsr(operation)
      when :NOP
        execute_operation_nop(operation)
      when :NOPD
        execute_operation_nopd(operation)
      when :NOPI
        execute_operation_nopi(operation)
      when :ORA
        execute_operation_ora(operation)
      when :PHA
        execute_operation_pha(operation)
      when :PHP
        execute_operation_php(operation)
      when :PLA
        execute_operation_pla(operation)
      when :PLP
        execute_operation_plp(operation)
      when :RLA
        execute_operation_rla(operation)
      when :ROL
        execute_operation_rol(operation)
      when :ROR
        execute_operation_ror(operation)
      when :RRA
        execute_operation_rra(operation)
      when :RTI
        execute_operation_rti(operation)
      when :RTS
        execute_operation_rts(operation)
      when :SAX
        execute_operation_sax(operation)
      when :SBC
        execute_operation_sbc(operation)
      when :SEC
        execute_operation_sec(operation)
      when :SED
        execute_operation_sed(operation)
      when :SEI
        execute_operation_sei(operation)
      when :SLO
        execute_operation_slo(operation)
      when :SRE
        execute_operation_sre(operation)
      when :STA
        execute_operation_sta(operation)
      when :STX
        execute_operation_stx(operation)
      when :STY
        execute_operation_sty(operation)
      when :TAX
        execute_operation_tax(operation)
      when :TAY
        execute_operation_tay(operation)
      when :TSX
        execute_operation_tsx(operation)
      when :TXA
        execute_operation_txa(operation)
      when :TXS
        execute_operation_txs(operation)
      when :TYA
        execute_operation_tya(operation)
      else
        raise ::Rnes::Errors::UnknownOperationError, "Unknown operation: #{operation.name}"
      end
    end

    # @param [Rnes::Operation] operation
    def execute_operation_adc(operation)
      result = fetch_value_by_addressing_mode_with_optional_read(operation.addressing_mode) + registers.x + registers.carry_bit
      adjust_carry_bit(result)
      adjust_negative_bit(result)
      adjust_overflow_bit(result)
      adjust_zero_bit(result)
      registers.a = result & 0xFF
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_and(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_asl(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_bcc(operation)
      unless registers.has_carry_bit?
        address = fetch_value_by_addressing_mode(operation.addressing_mode)
        branch(address)
      end
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_bcs(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_beq(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_bit(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_bmi(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_bne(operation)
      value = fetch_value_by_addressing_mode(operation.addressing_mode)
      unless registers.has_zero_bit?
        registers.pc = value
      end
    end

    # @param [Rnes::Operation] operation
    def execute_operation_bpl(operation)
      unless registers.has_negative_bit?
        registers.pc = fetch_value_by_addressing_mode(operation.addressing_mode)
      end
    end

    # @param [Rnes::Operation] operation
    def execute_operation_brk(_operation)
      registers.toggle_break_bit(true)
      stack_program_counter
      stack_status
      unless registers.has_interrupt_bit?
        registers.toggle_interrupt_bit(true)
        registers.pc = read_word(0xFFFE)
      end
      registers.pc -= 1
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_bvc(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_bvs(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_clc(_operation)
      registers.toggle_carry_bit(true)
    end

    # @param [Rnes::Operation] operation
    def execute_operation_cld(_operation)
      registers.toggle_decimal_bit(false)
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_cli(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_clv(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_cmp(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_cpx(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_cpy(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_dcp(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_dec(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_dex(_operation)
      result = registers.x - 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.x = result & 0xFF
    end

    # @param [Rnes::Operation] operation
    def execute_operation_dey(_operation)
      result = registers.y - 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.y = result & 0xFF
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_eor(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_inx(_operation)
      result = registers.x + 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.x = result & 0xFF
    end

    # @param [Rnes::Operation] operation
    def execute_operation_iny(_operation)
      result = registers.y + 1
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.y = result & 0xFF
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_isb(_operation)
      raise NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_jmp(operation)
      registers.pc = fetch_value_by_addressing_mode(operation.addressing_mode)
    end

    # @param [Rnes::Operation] operation
    def execute_operation_jsr(operation)
      registers.pc -= 1
      stack_program_counter
      registers.pc = fetch_value_by_addressing_mode(operation.addressing_mode)
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_lax(_operation)
      raise NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_lda(operation)
      result = fetch_value_by_addressing_mode_with_optional_read(operation.addressing_mode)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.a = result
    end

    # @param [Rnes::Operation] operation
    def execute_operation_ldx(operation)
      result = fetch_value_by_addressing_mode_with_optional_read(operation.addressing_mode)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.x = result
    end

    # @param [Rnes::Operation] operation
    def execute_operation_ldy(operation)
      result = fetch_value_by_addressing_mode_with_optional_read(operation.addressing_mode)
      adjust_negative_bit(result)
      adjust_zero_bit(result)
      registers.y = result
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_lsr(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_nop(_operation)
    end

    # @param [Rnes::Operation] operation
    def execute_operation_nopd(_operation)
      registers.pc += 1
    end

    # @param [Rnes::Operation] operation
    def execute_operation_nopi(_operation)
      registers.pc += 2
    end

    # @param [Rnes::Operation] operation
    def execute_operation_ora(operation)
      value = registers.a | fetch_value_by_addressing_mode_with_optional_read(operation.addressing_mode)
      adjust_negative_bit(value)
      adjust_zero_bit(value)
      registers.a = value % 0xFF
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_pha(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_php(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_pla(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_plp(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_rla(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_rol(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_ror(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_rra(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_rti(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_rts(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_sax(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_sbc(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_sec(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_sed(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_sei(_operation)
      registers.toggle_interrupt_bit(true)
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_slo(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_sre(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_sta(operation)
      address = fetch_value_by_addressing_mode(operation.addressing_mode)
      write(address, registers.a)
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_stx(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_sty(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_tax(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_tay(_operation)
      raise ::NotImplementedError
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_tsx(_operation)
      raise ::NotImplementedError
    end

    # @param [Rnes::Operation] operation
    def execute_operation_txa(_operation)
      value = registers.x
      adjust_negative_bit(value)
      adjust_zero_bit(value)
      registers.a = value
    end

    # @param [Rnes::Operation] operation
    def execute_operation_txs(_operation)
      registers.sp = registers.x + 0x100
    end

    # @todo
    # @param [Rnes::Operation] operation
    def execute_operation_tya(_operation)
      raise ::NotImplementedError
    end

    # @return [Integer]
    def fetch
      address = @registers.pc
      value = read(address)
      @registers.pc += 1
      value
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
      offset = fetch
      offset -= 256 if offset >= 128
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

    # @param [Integer] value
    def stack(value)
      write(registers.sp | 0x100, value)
      registers.sp -= 1
    end

    def stack_program_counter
      stack_word(registers.pc)
    end

    def stack_status
      stack(registers.p)
    end

    # @param [Integer] value
    def stack_word(value)
      stack(value >> 8)
      stack(value & 0xFF)
    end

    # @return [Integer]
    def unstack
      registers.sp += 1
      read(registers.sp & 0xFF | 0x100)
    end

    # @param [Integer] address
    # @param [Integer] value
    def write(address, value)
      @bus.write(address, value)
    end
  end
end
