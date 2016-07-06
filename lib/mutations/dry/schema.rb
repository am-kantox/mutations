module Mutations
  module Dry
    module Schema
      def schema
        @schema ||= derived_schema
        block_given? ? @schema = ::Dry::Validation.Schema(@schema, &Proc.new) : @schema
      end

      def required
        @current = __callee__
        instance_eval(&Proc.new) if block_given?
        @current = nil
      end
      alias_method :optional, :required

      # FIXME: try-catch and call super in rescue clause
      def method_missing m, *args, &cb
        puts "==> [MM] “#{m}” called with args: “#{args.inspect}”"
        name, current = args.shift, @current
        schema do
          configure do
            define_method(:"#{name}?") do |value|
              true # FIXME
            end
          end

          __send__(current, name) { __send__ :"#{name}?" }
        end
      end

      def ~@
        # schema
      end

      ##########################################################################
      ### type declaration DSL
      ##########################################################################

      # FIXME: errors in double+ nested hashes are not nested! dry-rb glitch?
      def hash name
        current = @current # closure scope
        nested = Class.new(Instance).init(current, &Proc.new)
        schema { __send__(current, name).schema(nested) }

        define_method(name) { Mutations::Init.hashify @inputs[name] } unless is_a?(Instance)
      end

      # FIXME: array of anonymous objects
      def array name, &cb
        current = @current # closure scope
        nested =  begin
                    Class.new(Instance).init(current, &cb)
                  rescue AnonymousTypeDetected => err
                    build_type err.type
                  end
        name.nil? ? schema { each(nested) } : schema { __send__(current, name).each(nested) }
        define_method(name) { @inputs[name] } unless is_a?(Instance)
      end

      def generic_type name = nil, **params
        fail AnonymousTypeDetected.new(__callee__) if name.nil?

        # FIXME: :strip => true and siblings should be handled with procs?
        current = @current # closure scope
        opts = params[:empty] ? {} : build_opts(__callee__, params)
        type = [params[:nils] ? :maybe : :filled, build_type(__callee__)]
        schema do
          scope = __send__(current, name)
          opts.empty? ? scope.__send__(*type) : scope.__send__(*type, **opts)
        end
        unless is_a?(Instance)
          define_method(name) { @inputs[name] }
          define_method(:"#{name}_present?") { @inputs.key?(name) }
          define_method(:"#{name}=") { |value| @inputs[name] = value }
        end
      end

      %i(string integer float).each do |m|
        alias_method m, :generic_type
      end

      private :generic_type

    private

      def derived_schema
        this = is_a?(Class) ? self : self.class
        parent_with_schema = this.ancestors.tap(&:shift).detect do |klazz|
          break if klazz == Mutations::Dry::Command
          klazz.respond_to?(:schema) && klazz.schema.is_a?(::Dry::Validation::Schema)
        end
        parent_with_schema ? Class.new(parent_with_schema.schema.class).new : empty_schema
      end

      def empty_schema
        ::Dry::Validation.Schema do
          configure do
            config.input_processor = :sanitizer
          end
        end
      end

      ##########################################################################
      ### generic helpers / builders
      ##########################################################################

      def build_type type
        case type.to_s
        when 'string', 'integer' then :"#{type[0...3]}?"
        else :"#{type}?"
        end
      end

      def build_opts type, params
        __send__(:"build_opts_#{type}", params).reject { |_, v| v.nil? }
      end

      # ====== validators ======
      # :nils => false,          # true allows an explicit nil to be valid. Overrides any other options
      # :empty => false,         # false disallows "".  true allows "" and overrides any other validations (b/c they couldn't be true if it's empty)
      # :min_length => nil,      # Can be a number like 5, meaning that 5 codepoints are required
      # :max_length => nil,      # Can be a number like 10, meaning that at most 10 codepoints are permitted
      # :matches => nil,         # Can be a regexp
      # :in => nil,              # Can be an array like %w(red blue green)

      # ====== formatters ======
      # ★ :strip => true,          # true calls data.strip if data is a string
      # ★ :strict => false,        # If false, then symbols, numbers, and booleans are converted to a string with to_s.
      # ★ :discard_empty => false, # If the param is optional, discard_empty: true drops empty fields.
      # ★ :allow_control_characters => false    # false removes unprintable characters from the string
      def build_opts_string params
        {
          min_size?:    (params[:min_length] || 1 if params[:min_length]),
          max_size?:    (params[:max_length] if params[:max_length]),
          format?:      (params[:matches] if params[:matches]),
          included_in?: (params[:in] if params[:in])
        }
      end

      # ====== validators ======
      # :nils => false,          # true allows an explicit nil to be valid. Overrides any other options
      # :min => nil,             # Can be a number like 5, meaning that 5 codepoints are required
      # :max => nil,             # Can be a number like 10, meaning that at most 10 codepoints are permitted
      # :in => nil,              # Can be an array like %w(red blue green)

      # ====== formatters ======
      # ★ :empty_is_nil => false,  # if true, treat empty string as if it were nil
      def build_opts_integer params
        {
          min_size?:    (params[:min] if params[:min]),
          max_size?:    (params[:max] if params[:max]),
          included_in?: (params[:in] if params[:in])
        }
      end

      class Instance
        singleton_class.prepend Mutations::Dry::Schema

        def self.init current
          @current = current
          instance_eval(&Proc.new) if block_given?
          schema
        end
      end
    end
  end
end

Mutations::Command.singleton_class.prepend Mutations::Dry::Schema
