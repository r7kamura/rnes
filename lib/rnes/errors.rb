module Rnes
  module Errors
    class BaseError < ::StandardError
    end

    class InvalidInesFormatError < BaseError
    end
  end
end
