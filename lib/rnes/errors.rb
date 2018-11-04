module Rnes
  module Errors
    class BaseError < ::StandardError
    end

    class CharacterRomNotConnectedError < BaseError
    end

    class InvalidCpuBusAddressError < BaseError
    end

    class InvalidInesFormatError < BaseError
    end

    class InvalidPpuBusAddressError < BaseError
    end

    class ProgramRomNotConnectedError < BaseError
    end

    class UnknownAddressingModeError < BaseError
    end

    class UnknownOperationCodeError < BaseError
    end

    class UnknownOperationError < BaseError
    end

    class UnknownPpuAddressError < BaseError
    end
  end
end
