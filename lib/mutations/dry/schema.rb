module Mutations
  module Dry
    module Schema
      USE_HASHIE_MASH = begin
        require 'hashie/mash'
        true
      rescue LoadError => e
        $stderr.puts [
          '[DRY] Could not find Hashie::Mash.',
          'You probably want to install it / add it to your Gemfile.',
          "Error: [#{e.message}]."
        ].join($/)
      end

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
        nested = Class.new(Instance).tap do |inst|
          inst.instance_variable_set(:@current, current)
          inst.instance_eval(&Proc.new)
        end.schema
        schema do
          __send__(current, name).schema(nested)
        end
        define_method(name) do
          USE_HASHIE_MASH ? Kernel.const_get('Hashie::Mash').new(@inputs[name]) : @inputs[name]
        end unless is_a?(Instance)
      end

      def generic_type name, **params
        # FIXME: :strip => true and siblings should be handled with procs?
        current = @current # closure scope
        type = [params[:nils] ? :maybe : :filled, build_type(__callee__)]
        opts = params[:empty] ? {} : build_opts(__callee__, params)
        puts type.inspect << $/ << opts.inspect
        schema do
          scope = __send__(current, name)
          opts.empty? ? scope.__send__(*type) : scope.__send__(*type, **opts)
        end
        define_method(name) { @inputs[name] } unless is_a?(Instance)
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
        parent_with_schema ? Class.new(parent_with_schema.schema.class).new : ::Dry::Validation::Schema::Form
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
      end
    end
  end
end

Mutations::Command.singleton_class.prepend Mutations::Dry::Schema
