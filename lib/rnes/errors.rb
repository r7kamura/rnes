module Rnes
  module Errors
    class BaseError < ::StandardError
    end

    class InvalidAddressError < BaseError
    end

    class InvalidInesFormatError < BaseError
    end

    class ProgramRomNotConnectedError < BaseError
    end
  end
end
