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
        @inputs = @validation.output

        # dry: {:name=>["size cannot be greater than 10"],
        #       :properties=>{:first_arg=>["must be a string", "is in invalid format"]},
        #       :second_arg=>{:second_sub_arg=>["must be one of: 42"]},
        #       :amount=>["must be one of: 42"]}}
        # mut: {:name=>#<Mutations::ErrorAtom:0x00000009534e50 @key=:name, @symbol=:max_length, @message=nil, @index=nil>,
        #       :properties=>{
        #           :second_arg=>{:second_sub_arg=>#<Mutations::ErrorAtom:0x000000095344a0 @key=:second_sub_arg, @symbol=:in, @message=nil, @index=nil>}
        #       :amount=>#<Mutations::ErrorAtom:0x00000009534068 @key=:amount, @symbol=:in, @message=nil, @index=nil>}
        @errors = @validation.messages.map.with_index do |(k, v), idx|
          [k, dig(k, v, idx)]
        end.to_h

        # Run a custom validation method if supplied:
        validate unless has_errors?
      end

    private

      def dig key, value, idx
        case value
        when Hash then value.map { |k, v| [k, dig(k, v, idx)] }.to_h
        else ErrorAtom.new(key, symbol(key), message: [*value].join(', '), index: idx)
        end
      end

      # Yeah, I know this is an ugly hack. So what?
      def symbol key
        @validation.errors.detect { |e| e.name == key }.result.rule.predicate.id
      rescue
        "#{key}_guard".to_sym # FIXME
      end
    end
  end
end

Mutations::Command.prepend Mutations::Dry::Command
