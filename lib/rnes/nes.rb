require 'rnes/cpu_bus'

module Rnes
  class Nes
    def initialize
      cpu_bus = ::Rnes::CpuBus.new
      @cpu = ::Rnes::Cpu.new(cpu_bus)
    end

    # @todo
    def run
      @cpu.reset
    end
  end
end
