module Mutations
  module Dry
    module Predicates
      include ::Dry::Logic::Predicates

      predicate(:duck?) do |expected, current|
        expected.nil? || expected.empty? || expected.all?(&current.method(:respond_to?))
      end
    end
  end
end
