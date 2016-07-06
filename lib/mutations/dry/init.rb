module Mutations
  module Init
    begin
      require 'dry-validation'
      require 'mutations/dry/monkeypatches'
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
end
