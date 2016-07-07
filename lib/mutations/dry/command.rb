module Mutations
  module Dry
    module Command
      attr_reader :validation
      def initialize(*args)
        @raw_inputs = args.inject({}.with_indifferent_access) do |h, arg|
          fail ArgumentError.new("All arguments must be hashes") unless arg.is_a?(Hash)
          h.merge!(arg)
        end

        @validation = self.class.schema.(@raw_inputs)
        @inputs = Mutations::Init.hashify @validation.output

        # dry: {:name=>["size cannot be greater than 10"],
        #       :properties=>{:first_arg=>["must be a string", "is in invalid format"]},
        #       :second_arg=>{:second_sub_arg=>["must be one of: 42"]},
        #       :amount=>["must be one of: 42"]}}
        # mut: {:name=>#<Mutations::ErrorAtom:0x00000009534e50 @key=:name, @symbol=:max_length, @message=nil, @index=nil>,
        #       :properties=>{
        #           :second_arg=>{:second_sub_arg=>#<Mutations::ErrorAtom:0x000000095344a0 @key=:second_sub_arg, @symbol=:in, @message=nil, @index=nil>}
        #       :amount=>#<Mutations::ErrorAtom:0x00000009534068 @key=:amount, @symbol=:in, @message=nil, @index=nil>}
        @errors = ::Mutations::Dry::ErrorAtom.patch_message_set(
          ::Dry::Validation::ErrorCompiler.new(
            ::Dry::Validation::Schema.messages
          ).(@validation.to_ast.last)
        )

        # Run a custom validation method if supplied:
        validate unless has_errors?
      end

      def messages
        @messages ||= @errors.values.map(&:dry_message)
      end
    end
  end
end

Mutations::Command.prepend Mutations::Dry::Command
