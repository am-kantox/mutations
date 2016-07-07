module Mutations
  module Dry
    class AnonymousTypeDetected < StandardError
      attr_reader :type, :cause
      def initialize type, cause = nil
        @type = type
        @cause = cause
      end
    end

    class TypeError < StandardError
    end

    class ErrorAtom < ::Mutations::ErrorAtom
      ::Dry::Validation::Message.instance_methods(false).each do |mm|
        define_method(mm) do |*args, &cb|
          @dry_message.send mm, *args, &cb
        end
      end

      attr_reader :dry_message

      def initialize(key, error_symbol, dry_message, options = {})
        super key, ::Mutations::Dry::MAP[error_symbol] || error_symbol, options
        @dry_message = dry_message
      end

      def self.patch_message_set(set)
        fail TypeError, "Expected: ::Dry::Validation::MessageSet; got: #{set.class}" unless set.is_a?(::Dry::Validation::MessageSet)
        atoms = set.map.with_index.with_object(ErrorHash.new) do |(msg, idx), memo|
          memo[msg.path.join('.')] = ::Mutations::Dry::ErrorAtom.new(msg.path.join('.'), msg.predicate, msg, message: msg.text, index: idx)
        end
        atoms.empty? ? nil : atoms
      end
    end

    class ErrorCompiler < ::Dry::Validation::ErrorCompiler
      # visit_error: [:name, [:input, [:name, [:result, ["Aleksei Matiushkin", [:key, [:name, [:predicate, [:max_size?, [[:num, 10], [:input, "Aleksei Matiushkin"]]]]]]]]]]]
      # visit_error: [[:properties, :first_arg], [:input, [:first_arg, [:result, [42, [:key, [:first_arg, [:predicate, [:str?, [[:input, 42]]]]]]]]]]]
      # visit_error: [[:second_arg, :second_sub_arg], [:input, [:second_sub_arg, [:result, ["0", [:key, [:second_sub_arg, [:predicate, [:int?, [[:input, "0"]]]]]]]]]]]
      # visit_error: [:amount, [:input, [:amount, [:result, [0, [:key, [:amount, [:predicate, [:included_in?, [[:list, [42]], [:input, 0]]]]]]]]]]]
      def visit_error(node, opts = ::Dry::Validation::EMPTY_HASH)
        rule, error = node
        node_path = Array(opts.fetch(:path, rule))

        path = if rule.is_a?(Array) && rule.size > node_path.size
                 rule
               else
                 node_path
               end

        path.compact!

        text = messages[rule]

        if text
          ::Mutations::Dry::ErrorAtom.new(
            [*node.first].join('.'),
            predicate,
            ::Dry::Validation::Message.new(node, path, text, rule: rule),
            message: text
          )
        else
          visit(error, opts.merge(path: path))
        end
      end
    end

    ::Dry::Validation::Schema.instance_variable_set(
      :@error_compiler,
      Mutations::Dry::ErrorCompiler.new(::Dry::Validation::Schema.messages)
    )
  end
end
