require 'rnes/cpu_bus'
require 'rnes/cpu_registers'
require 'rnes/errors'
require 'rnes/operation'

module Rnes
  class Cpu
    # @return [Rnes::CpuBus] bus
    attr_reader :bus

    # @return [Rnes::CpuRegisters]
    attr_reader :registers

    # @param [Rnes::CpuBus] bus
    # @param [Rnes::InterruptLine] interrupt_line
    def initialize(bus:, interrupt_line:)
      @branched = false
      @bus = bus
      @interrupt_line = interrupt_line
      @registers = ::Rnes::CpuRegisters.new
    end

    # @note For logging.
    # @return [Rnes::Operation]
    def read_operation
      address = @registers.program_counter
      operation_code = read(address)
      ::Rnes::Operation.build(operation_code)
    end

    def reset
      @registers.reset
      @registers.program_counter = read_word(0xFFFC)
    end

    # @return [Integer]
    def step
      handle_interrupts
      operation = fetch_operation
      operand = fetch_operand_by(operation.addressing_mode)
      execute_operation(
        addressing_mode: operation.addressing_mode,
        operand: operand,
        operation_name: operation.name,
      )
      @branched = false
      operation.cycle
    end

    private

    # @param [Integer] address
    def branch(address)
      @branched = true
      @registers.program_counter = address
    end

    # @param [Symbol] addressing_mode
    # @param [Integer, nil] operand
    # @param [Symbol] operation_name
    # @return [Integer]
    def execute_operation(addressing_mode:, operand:, operation_name:)
      case operation_name
      when :ADC
        if addressing_mode == :immediate
          execute_operation_adc_for_immediate_addressing(operand)
        else
          execute_operation_adc_for_non_immediate_addressing(operand)
        end
      when :AND
        if addressing_mode == :immediate
          execute_operation_and_for_immediate_addressing(operand)
        else
          execute_operation_and_for_non_immediate_addressing(operand)
        end
      when :ASL
        if addressing_mode == :accumulator
          execute_operation_asl_for_accoumulator(operand)
        else
          execute_operation_asl_for_non_accumulator(operand)
        end
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
        if addressing_mode == :immediate
          execute_operation_cmp_for_immediate_addressing(operand)
        else
          execute_operation_cmp_for_non_immediate_addressing(operand)
        end
      when :CPX
        if addressing_mode == :immediate
          execute_operation_cpx_for_immediate_addressing(operand)
        else
          execute_operation_cpx_for_non_immediate_addressing(operand)
        end
      when :CPY
        if addressing_mode == :immediate
          execute_operation_cpy_for_immediate_addressing(operand)
        else
          execute_operation_cpy_for_non_immediate_addressing(operand)
        end
      when :DCP
        execute_operation_dcp(operand)
      when :DEC
        execute_operation_dec(operand)
      when :DEX
        execute_operation_dex(operand)
      when :DEY
        execute_operation_dey(operand)
      when :EOR
        if addressing_mode == :immediate
          execute_operation_eor_for_immediate_addressing(operand)
        else
          execute_operation_eor_for_non_immediate_addressing(operand)
        end
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
        if addressing_mode == :immediate
          execute_operation_lda_for_immediate_addressing(operand)
        else
          execute_operation_lda_for_non_immediate_addressing(operand)
        end
      when :LDX
        if addressing_mode == :immediate
          execute_operation_ldx_for_immediate_addressing(operand)
        else
          execute_operation_ldx_for_non_immediate_addressing(operand)
        end
      when :LDY
        if addressing_mode == :immediate
          execute_operation_ldy_for_immediate_addressing(operand)
        else
          execute_operation_ldy_for_non_immediate_addressing(operand)
        end
      when :LSR
        if addressing_mode == :accumulator
          execute_operation_lsr_for_accumulator(operand)
        else
          execute_operation_lsr_for_non_accumulator(operand)
        end
      when :NOP
        execute_operation_nop(operand)
      when :NOPD
        execute_operation_nopd(operand)
      when :NOPI
        execute_operation_nopi(operand)
      when :ORA
        if addressing_mode == :immediate
          execute_operation_ora_for_immediate_addressing(operand)
        else
          execute_operation_ora_for_non_immediate_addressing(operand)
        end
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
        if addressing_mode == :accumulator
          execute_operation_rol_for_accumulator(operand)
        else
          execute_operation_rol_for_non_accumulator_(operand)
        end
      when :ROR
        if addressing_mode == :accumulator
          execute_operation_ror_for_accumulator(operand)
        else
          execute_operation_ror_for_non_accumulator(operand)
        end
      when :RRA
        execute_operation_rra(operand)
      when :RTI
        execute_operation_rti(operand)
      when :RTS
        execute_operation_rts(operand)
      when :SAX
        execute_operation_sax(operand)
      when :SBC
        if addressing_mode == :immediate
          execute_operation_sbc_for_immediate_addressing(operand)
        else
          execute_operation_sbc_for_non_immediate_addressing(operand)
        end
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
        raise ::Rnes::Errors::InvalidOperationError, "Invalid operation: #{operation_name}"
      end
    end

    # @param [Integer] operand
    def execute_operation_adc_for_immediate_addressing(operand)
      result = operand + @registers.accumulator + @registers.carry_bit
      @registers.carry = result > 0xFF
      @registers.negative = result[7] == 1
      @registers.overflow = (@registers.accumulator ^ operand)[7].zero? && !(@registers.accumulator ^ result)[7].zero?
      @registers.zero = result.zero?
      @registers.accumulator = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_adc_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_adc_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_and_for_immediate_addressing(operand)
      result = operand & @registers.accumulator
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_and_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_and_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_asl_for_accoumulator(_operand)
      value = @registers.accumulator
      result = (value << 1) && 0xFF
      @registers.carry = value[7] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_asl_for_non_accumulator(operand)
      value = read(operand)
      result = (value << 1) && 0xFF
      @registers.carry = value[7] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_bcc(operand)
      unless @registers.carry?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bcs(operand)
      if @registers.carry?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_beq(operand)
      if @registers.zero?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bit(operand)
      result = read(operand)
      @registers.overflow = result[6] == 1
      @registers.negative = result[7] == 1
      @registers.zero = (@registers.accumulator & result).zero?
    end

    # @param [Integer] operand
    def execute_operation_bmi(operand)
      unless @registers.negative?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bne(operand)
      unless @registers.zero?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bpl(operand)
      unless @registers.negative?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_brk(_operand)
      @registers.break = true
      @registers.program_counter += 1
      push_word(@registers.program_counter)
      push(@registers.status)
      unless @registers.interrupt?
        @registers.interrupt = true
        @registers.program_counter = read_word(0xFFFE)
      end
      @registers.program_counter -= 1
    end

    # @param [Integer] operand
    def execute_operation_bvc(operand)
      unless @registers.overflow?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_bvs(operand)
      if @registers.overflow?
        branch(operand)
      end
    end

    # @param [Integer] operand
    def execute_operation_clc(_operand)
      @registers.carry = false
    end

    # @param [Integer] operand
    def execute_operation_cld(_operand)
      @registers.decimal = false
    end

    # @param [Integer] operand
    def execute_operation_cli(_operand)
      @registers.interrupt = false
    end

    # @param [Integer] operand
    def execute_operation_clv(_operand)
      @registers.overflow = false
    end

    # @param [Integer] operand
    def execute_operation_cmp_for_immediate_addressing(operand)
      result = @registers.accumulator - operand
      @registers.carry = result >= 0
      @registers.negative = result[7] == 1
      @registers.zero = (result & 0xFF).zero?
    end

    # @param [Integer] operand
    def execute_operation_cmp_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_cmp_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_cpx_for_immediate_addressing(operand)
      result = @registers.index_x - operand
      @registers.carry = result >= 0
      @registers.negative = result[7] == 1
      @registers.zero = (result & 0xFF).zero?
    end

    # @param [Integer] operand
    def execute_operation_cpx_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_cpx_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_cpy_for_immediate_addressing(operand)
      result = @registers.index_y - operand
      @registers.carry = result >= 0
      @registers.negative = result[7] == 1
      @registers.zero = (result & 0xFF).zero?
    end

    # @param [Integer] operand
    def execute_operation_cpy_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_cpy_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_dcp(operand)
      result = (read(operand) - 1) & 0xFF
      sub_result = (@registers.accumulator - result) & 0x1FF
      @registers.negative = sub_result[7] == 1
      @registers.zero = sub_result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_dec(operand)
      result = (read(operand) - 1) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_dex(_operand)
      result = (@registers.index_x - 1) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_dey(_operand)
      result = (@registers.index_y - 1) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_y = result
    end

    # @param [Integer] operand
    def execute_operation_eor_for_immediate_addressing(operand)
      result = (operand ^ @registers.accumulator) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_eor_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_eor_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_inc(operand)
      result = (read(operand) + 1) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_inx(_operand)
      result = (@registers.index_x + 1) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_iny(_operand)
      result = (@registers.index_y + 1) & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_y = result
    end

    # @param [Integer] operand
    def execute_operation_isb(operand)
      value = (read(operand) + 1) & 0xFF
      result = (~value & 0xFF) + @registers.accumulator + @registers.carry_bit
      @registers.overflow = (@registers.accumulator ^ value)[7].zero? && !(@registers.accumulator ^ result)[7].zero?
      @registers.carry = result > 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result & 0xFF
      write(operand, value)
    end

    # @param [Integer] operand
    def execute_operation_jmp(operand)
      @registers.program_counter = operand
    end

    # @param [Integer] operand
    def execute_operation_jsr(operand)
      push_word(@registers.program_counter - 1)
      @registers.program_counter = operand
    end

    # @param [Integer] operand
    def execute_operation_lax(operand)
      result = read(operand)
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
      @registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_lda_for_immediate_addressing(operand)
      @registers.negative = operand[7] == 1
      @registers.zero = operand.zero?
      @registers.accumulator = operand
    end

    # @param [Integer] operand
    def execute_operation_lda_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_lda_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_ldx_for_immediate_addressing(operand)
      @registers.negative = operand[7] == 1
      @registers.zero = operand.zero?
      @registers.index_x = operand
    end

    # @param [Integer] operand
    def execute_operation_ldx_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_ldx_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_ldy_for_immediate_addressing(operand)
      @registers.negative = operand[7] == 1
      @registers.zero = operand.zero?
      @registers.index_y = operand
    end

    # @param [Integer] operand
    def execute_operation_ldy_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_ldy_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_lsr_for_accumulator(_operand)
      value = @registers.accumulator
      result = value >> 1
      @registers.carry = value[0] == 1
      @registers.negative = false
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_lsr_for_non_accumulator(operand)
      value = read(operand)
      result = value >> 1
      @registers.carry = value[0] == 1
      @registers.negative = false
      @registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_nop(operand)
    end

    # @param [Integer] operand
    def execute_operation_nopd(_operand)
      @registers.program_counter += 1
    end

    # @param [Integer] operand
    def execute_operation_nopi(_operand)
      @registers.program_counter += 2
    end

    # @param [Integer] operand
    def execute_operation_ora_for_immediate_addressing(operand)
      result = @registers.accumulator | operand
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_ora_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_ora_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_pha(_operand)
      push(@registers.accumulator)
    end

    # @param [Integer] operand
    def execute_operation_php(_operand)
      @registers.break = true
      push(@registers.status)
    end

    # @param [Integer] operand
    def execute_operation_pla(_operand)
      result = pop
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_plp(_operand)
      @registers.status = pop
      @registers.reserved = true
    end

    # @param [Integer] operand
    def execute_operation_rla(operand)
      value = (read(operand) << 1) + @registers.carry_bit
      result = (result & @registers.accumulator) & 0xFF
      @registers.carry = value[8] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
      write(operand, value)
    end

    # @param [Integer] operand
    def execute_operation_rol_for_accumulator(_operand)
      value = @registers.accumulator
      result = ((value << 1) | @registers.carry_bit) & 0xFF
      @registers.carry = value[7] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_rol_for_non_accumulator(operand)
      value = read(operand)
      result = ((value << 1) | @registers.carry_bit) & 0xFF
      @registers.carry = value[7] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_ror_for_accumulator(_operand)
      value = @registers.accumulator
      result = ((value >> 1) | (@registers.carry_bit << 7))
      @registers.carry = value[0] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_ror_for_non_accumulator(operand)
      value = read(operand)
      result = ((value >> 1) | (@registers.carry_bit << 7))
      @registers.carry = value[0] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_rra(operand)
      read_value = read(operand)
      value = (read_value >> 1) | (@registers.carry_bit << 7)
      result = value + @registers.accumulator + read_value[0]
      @registers.carry = result > 0xFF
      @registers.overflow = (@registers.accumulator ^ value)[7].zero? && !(@registers.accumulator ^ result)[7].zero?
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      write(operand, value)
    end

    # @param [Integer] operand
    def execute_operation_rti(_operand)
      @registers.status = pop
      @registers.program_counter = pop_word
      @registers.reserved = true
    end

    # @param [Integer] operand
    def execute_operation_rts(_operand)
      @registers.program_counter = pop_word
      @registers.program_counter += 1
    end

    # @param [Integer] operand
    def execute_operation_sax(operand)
      result = @registers.accumulator & @registers.index_x
      write(operand, result)
    end

    # @param [Integer] operand
    def execute_operation_sbc_for_immediate_addressing(operand)
      result = @registers.accumulator - operand - 1 + @registers.carry_bit
      @registers.overflow = ((@registers.accumulator ^ result) & 0x80 != 0 && ((@registers.accumulator ^ operand) & 0x80) != 0)
      @registers.carry = result >= 0
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result & 0xFF
    end

    # @param [Integer] operand
    def execute_operation_sbc_for_non_immediate_addressing(operand)
      operand = read(operand)
      execute_operation_sbc_for_immediate_addressing(operand)
    end

    # @param [Integer] operand
    def execute_operation_sec(_operand)
      @registers.carry = true
    end

    # @param [Integer] operand
    def execute_operation_sed(_operand)
      @registers.decimal = true
    end

    # @param [Integer] operand
    def execute_operation_sei(_operand)
      @registers.interrupt = true
    end

    # @param [Integer] operand
    def execute_operation_slo(operand)
      read_value = read(operand)
      value = (read_value << 1) & 0xFF
      result = value | @registers.accumulator
      @registers.carry = read_value[7] == 1
      @registers.negative = result == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
      write(operand, value)
    end

    # @param [Integer] operand
    def execute_operation_sre(operand)
      read_value = read(operand)
      value = read_value >> 1
      result = value ^ @registers.accumulator
      @registers.carry = read_value[0] == 1
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
      write(operand, value)
    end

    # @param [Integer] operand
    def execute_operation_sta(operand)
      write(operand, @registers.accumulator)
    end

    # @param [Integer] operand
    def execute_operation_stx(operand)
      write(operand, @registers.index_x)
    end

    # @param [Integer] operand
    def execute_operation_sty(operand)
      write(operand, @registers.index_y)
    end

    # @param [Integer] operand
    def execute_operation_tax(_operand)
      result = @registers.accumulator
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_tay(_operand)
      result = @registers.accumulator
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_y = result
    end

    # @param [Integer] operand
    def execute_operation_tsx(_operand)
      result = @registers.stack_pointer & 0xFF
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.index_x = result
    end

    # @param [Integer] operand
    def execute_operation_txa(_operand)
      result = @registers.index_x
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @param [Integer] operand
    def execute_operation_txs(_operand)
      @registers.stack_pointer = @registers.index_x + 0x100
    end

    # @param [Integer] operand
    def execute_operation_tya(_operand)
      result = @registers.index_y
      @registers.negative = result[7] == 1
      @registers.zero = result.zero?
      @registers.accumulator = result
    end

    # @return [Integer]
    def fetch
      address = @registers.program_counter
      value = read(address)
      @registers.program_counter += 1
      value
    end

    # @param [Symbol] addressing_mode
    def fetch_operand_by(addressing_mode)
      case addressing_mode
      when :absolute
        fetch_operand_by_absolute_addressing
      when :absolute_x
        fetch_operand_by_absolute_x_addressing
      when :absolute_y
        fetch_operand_by_absolute_y_addressing
      when :accumulator
        fetch_operand_by_accumulator_addressing
      when :immediate
        fetch_operand_by_immediate_addressing
      when :implied
        fetch_operand_by_implied_addressing
      when :indirect_absolute
        fetch_operand_by_indirect_absolute_addressing
      when :post_indexed_indirect
        fetch_operand_by_post_indexed_indirect_addressing
      when :pre_indexed_indirect
        fetch_operand_by_pre_indexed_indirect_addressing
      when :relative
        fetch_operand_by_relative_addressing
      when :zero_page
        fetch_operand_by_zero_page_addressing
      when :zero_page_x
        fetch_operand_by_zero_page_x_addressing
      when :zero_page_y
        fetch_operand_by_zero_page_y_addressing
      else
        raise ::Rnes::Errors::InvalidAddressingModeError, "Invalid addressing mode: #{addressing_mode}"
      end
    end

    # @return [Integer]
    def fetch_operand_by_absolute_addressing
      fetch_word
    end

    # @return [Integer]
    def fetch_operand_by_absolute_x_addressing
      (fetch_word + @registers.index_x) & 0xFFFF
    end

    # @return [Integer]
    def fetch_operand_by_absolute_y_addressing
      (fetch_word + @registers.index_y) & 0xFFFF
    end

    # @return [nil]
    def fetch_operand_by_accumulator_addressing
    end

    # @return [Integer]
    def fetch_operand_by_immediate_addressing
      fetch
    end

    # @return [nil]
    def fetch_operand_by_implied_addressing
    end

    # @return [Integer]
    def fetch_operand_by_indirect_absolute_addressing
      read_word(fetch_word)
    end

    # @return [Integer]
    def fetch_operand_by_pre_indexed_indirect_addressing
      read_word((fetch + @registers.index_x) & 0xFF)
    end

    # @return [Integer]
    def fetch_operand_by_post_indexed_indirect_addressing
      (read_word(fetch) + @registers.index_y) & 0xFF
    end

    # @return [Integer]
    def fetch_operand_by_relative_addressing
      int8 = fetch
      offset = int8[7] == 1 ? int8 - 256 : int8
      @registers.program_counter + offset
    end

    # @return [Integer]
    def fetch_operand_by_zero_page_addressing
      fetch
    end

    # @return [Integer]
    def fetch_operand_by_zero_page_x_addressing
      (fetch + @registers.index_x) & 0xFF
    end

    # @return [Integer]
    def fetch_operand_by_zero_page_y_addressing
      (fetch + @registers.index_y) & 0xFF
    end

    # @return [Rnes::Operation]
    def fetch_operation
      operation_code = fetch
      ::Rnes::Operation.build(operation_code)
    end

    # @return [Integer]
    def fetch_word
      fetch | (fetch << 8)
    end

    def handle_interrupts
      if @interrupt_line.nmi
        handle_nmi
      end
      if !@registers.interrupt? && @interrupt_line.irq
        handle_irq
      end
    end

    def handle_irq
      @interrupt_line.deassert_irq
      @registers.break = false
      push_word(@registers.program_counter)
      push(@registers.status)
      @registers.interrupt = true
      @registers.program_counter = read_word(0xFFFE)
    end

    def handle_nmi
      @interrupt_line.deassert_nmi
      @registers.break = false
      push_word(@registers.program_counter)
      push(@registers.status)
      @registers.interrupt = true
      @registers.program_counter = read_word(0xFFFA)
    end

    # @return [Integer]
    # @raise [Rnes::Errors::StackPointerOverflowError]
    def pop
      if @registers.stack_pointer < 0x1FF
        @registers.stack_pointer += 1
        read(@registers.stack_pointer)
      else
        raise ::Rnes::Errors::StackPointerOverflowError
      end
    end

    # @return [Integer]
    def pop_word
      pop | pop << 8
    end

    # @param [Integer] value
    # @raise [Rnes::Errors::StackPointerOverflowError]
    def push(value)
      if @registers.stack_pointer > 0x100
        write(@registers.stack_pointer, value)
        @registers.stack_pointer -= 1
      else
        raise ::Rnes::Errors::StackPointerOverflowError
      end
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
