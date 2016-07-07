module Mutations
  module Init
    begin
      require 'dry-validation'
      require 'mutations/dry/monkeypatches'
      require 'mutations/dry/errors'
      require 'mutations/dry/predicates'
      require 'mutations/dry/types'
      require 'mutations/dry/schema'
      require 'mutations/dry/command'
    rescue LoadError => e
      $stderr.puts [
        '[DRY] Unable to load dry validation extension.',
        'Make sure it is installed. Rolling back to standard impl.',
        "Error: [#{e.message}]."
      ].join($/)
    end

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

    # TODO: probably add an ability to stringify / symbolize keys
    def self.hashify hash
      case
      when Mutations::Init::USE_HASHIE_MASH
        Kernel.const_get('::Hashie::Mash').new(hash)
      else hash
      end
    end
  end

  module Dry
    MAP = {
      min_size?:    :min_length,
      max_size?:    :max_length,
      format?:      :matches,
      inclusion?:   :in, # deprecated in Dry
      included_in?: :in,
      gteq?:        :min,
      lteq?:        :max
    }

    # rubocop:disable Style/MethodName
    def self.Map params, keys = nil
      keys ||= MAP.keys
      keys.zip(MAP.values_at(*keys).map(&params.method(:[])))
          .to_h
          .reject { |_, v| v.nil? }
    end
    # rubocop:enable Style/MethodName
  end
end

module Dry
  module Mutations
    MAP = ::Mutations::Dry::MAP.invert
  end
end
