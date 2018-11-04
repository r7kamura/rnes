module Rnes
  module Errors
    class BaseError < ::StandardError
    end

    class BaseInvalidAddressError < BaseError
      # @param [Integer] address
      def initialize(address)
        @address = address
        super(to_s)
      end

      # @return [String]
      def to_s
        format('Invalid address: 0x%04X', @address)
      end
    end

    class InvalidAddressingModeError < BaseError
    end

    class InvalidCpuBusAddressError < BaseInvalidAddressError
    end

    class InvalidInesFormatError < BaseError
    end

    class InvalidOperationCodeError < BaseError
    end

    class InvalidOperationError < BaseError
    end

    class InvalidPpuAddressError < BaseInvalidAddressError
    end

    class InvalidPpuBusAddressError < BaseInvalidAddressError
    end

    class ProgramRomNotConnectedError < BaseError
    end
  end
end
