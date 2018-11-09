require 'rnes/operation/records'

module Rnes
  class Logger
    # @param [Rnes::Cpu] cpu
    # @param [String] path
    # @param [Rnes::Ppu] ppu
    def initialize(cpu:, path:, ppu:)
      @cpu = cpu
      @path = path
      @ppu = ppu
    end

    def puts
      file.puts(line)
    end

    private

    # @return [File]
    def file
      @file ||= ::File.open(@path, 'w')
    end

    # @return [String]
    def line
      [
        segment_cpu_program_counter,
        '',
        segment_operation_code,
        segment_operand,
        segment_operation_full_name,
        segment_operand_humanized,
        '',
        segment_cpu_accumulator,
        segment_cpu_index_x,
        segment_cpu_index_y,
        segment_cpu_status,
        segment_cpu_stack_pointer,
        segment_cycle,
        segment_ppu_line,
      ].join(' ')
    end

    # @return [String]
    def segment_cpu_accumulator
      format('A:%02X', @cpu.registers.accumulator)
    end

    # @return [String]
    def segment_cpu_index_x
      format('X:%02X', @cpu.registers.index_x)
    end

    # @return [String]
    def segment_cpu_index_y
      format('Y:%02X', @cpu.registers.index_y)
    end

    # @return [String]
    def segment_cpu_program_counter
      format('%04X', @cpu.registers.program_counter)
    end

    # @return [String]
    def segment_cpu_stack_pointer
      format('SP:%02X', @cpu.registers.stack_pointer - 0x100)
    end

    # @return [String]
    def segment_cpu_status
      format('P:%02X', @cpu.registers.status)
    end

    # @return [String]
    def segment_cycle
      format('CYC:%03d', @ppu.cycle)
    end

    # @return [String]
    def segment_operand
      program_counter = @cpu.registers.program_counter
      operation = @cpu.read_operation
      case operation.addressing_mode
      when :absolute, :absolute_x, :absolute_y, :indirect_absolute
        format('%02X %02X', @cpu.bus.read(program_counter + 1), @cpu.bus.read(program_counter + 2))
      when :immediate, :relative, :zero_page, :zero_page_x, :zero_page_y, :pre_indexed_indirect, :post_indexed_indirect
        format('%02X   ', @cpu.bus.read(program_counter + 1))
      else
        ' ' * 5
      end
    end

    # @return [String]
    def segment_operand_humanized
      operation = @cpu.read_operation
      program_counter = @cpu.registers.program_counter
      string = begin
        case operation.addressing_mode
        when :absolute, :absolute_x, :absolute_y, :indirect_absolute, :pre_indexed_absolute, :post_indexed_absolute
          format('$%02X%02X', @cpu.bus.read(program_counter + 2), @cpu.bus.read(program_counter + 1))
        when :immediate, :relative, :zero_page, :zero_page_x, :zero_oage_y
          format('#$%02X', @cpu.bus.read(program_counter + 1))
        else
          ''
        end
      end
      format('%-5s', string)
    end

    # @return [String]
    def segment_operation_code
      operation = @cpu.read_operation
      operation_code = ::Rnes::Operation::RECORDS.find_index(operation.to_hash)
      format('%02X', operation_code)
    end

    # @return [String]
    def segment_operation_full_name
      operation = @cpu.read_operation
      format('%-10s', operation.full_name)
    end

    # @note SL means "Scan Line".
    # @return [String]
    def segment_ppu_line
      format('SL:%03d', @ppu.line)
    end
  end
end
