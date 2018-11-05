module Rnes
  class InterruptLine
    # @return [Boolean]
    attr_reader :irq

    # @return [Boolean]
    attr_reader :nmi

    def initialize
      @irq = false
      @nmi = false
    end

    def assert_irq
      @irq = true
    end

    def assert_nmi
      @nmi = true
    end

    def deassert_irq
      @irq = false
    end

    def deassert_nmi
      @nmi = false
    end
  end
end
