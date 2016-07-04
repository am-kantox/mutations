begin
  require 'dry-validation'
rescue LoadError => e
  $stderr.puts [
    '[DRY] Unable to load dry validation extension.',
    'Make sure it is installed. Rolling back to standard impl.',
    "Error: [#{e.message}]."
  ].join($/)
end

module Mutations
  module Dry
    module Schema
      def required
        @current = __callee__
        instance_eval(&Proc.new) if block_given?
        @current = nil
      end
      alias_method :optional, :required

      def schema
        @schema ||= ::Dry::Validation::Schema
        @schema = block_given? ? ::Dry::Validation.Schema(@schema, &Proc.new) : @schema
      end

      def method_missing m, *args, &cb
        name, current = args.shift, @current
        schema do
          configure do
            define_method(:"#{name}?") do |value|
              true
            end
          end

          __send__(current, name) { __send__ :"#{name}?" }
        end
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
      def string name, **params
        # FIXME: :strip => true and siblings should be handled with procs?
        current = @current # closure scope
        type = [params[:nils] ? :maybe : :filled, :str?]
        opts = params[:empty] ? {} : {
          min_size?:  (params[:min_length] || 1 if params[:min_length]),
          max_size?:  (params[:max_length] if params[:max_length]),
          format?:    (params[:matches] if params[:matches]),
          inclusion?: (params[:in] if params[:in])
        }.reject { |_, v| v.nil? }
        puts res.inspect << $/ << type.inspect << $/ << opts.inspect
        schema do
          __send__(current, name).__send__(*type).value(**opts)
        end
      end

      # ====== validators ======
      # :nils => false,          # true allows an explicit nil to be valid. Overrides any other options
      # :min => nil,             # Can be a number like 5, meaning that 5 codepoints are required
      # :max => nil,             # Can be a number like 10, meaning that at most 10 codepoints are permitted
      # :in => nil,              # Can be an array like %w(red blue green)

      # ====== formatters ======
      # ★ :empty_is_nil => false,  # if true, treat empty string as if it were nil
      def integer name, **params
        current = @current # closure scope
        type = [params[:nils] ? :maybe : :filled, :int?]
        opts = params[:empty] ? {} : {
          min_size?:  (params[:min] if params[:min]),
          max_size?:  (params[:max] if params[:max]),
          inclusion?: (params[:in] if params[:in])
        }.reject { |_, v| v.nil? }
        puts res.inspect << $/ << type.inspect << $/ << opts.inspect
        schema do
          __send__(current, name).__send__(*type).value(**opts)
        end
      end
    end
  end
end

Mutations::Command.singleton_class.send :prepend, Mutations::Dry::Schema
