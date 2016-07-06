module Mutations
  module Dry
    class AnonymousTypeDetected < StandardError
      attr_reader :type, :cause
      def initialize type, cause = nil
        @type = type
        @cause = cause
      end
    end
  end
end
