module Mutations
  module Dry
    module Types
      include ::Dry::Types.module
    end

    class StrippedString < String
      def initialize str = '', **params
        params.empty? ? super(str.strip) : super(str.strip, **params)
      end
    end
  end
end
