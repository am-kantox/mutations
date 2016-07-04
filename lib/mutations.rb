require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'date'
require 'time'
require 'bigdecimal'

require 'mutations/version'
require 'mutations/exception'
require 'mutations/errors'
require 'mutations/input_filter'
require 'mutations/additional_filter'
require 'mutations/string_filter'
require 'mutations/integer_filter'
require 'mutations/float_filter'
require 'mutations/boolean_filter'
require 'mutations/duck_filter'
require 'mutations/date_filter'
require 'mutations/time_filter'
require 'mutations/file_filter'
require 'mutations/model_filter'
require 'mutations/array_filter'
require 'mutations/hash_filter'
require 'mutations/outcome'
require 'mutations/command'

module Mutations
  class << self
    attr_writer :error_message_creator, :cache_constants, :use_standard_impl

    def error_message_creator
      @error_message_creator ||= DefaultErrorMessageCreator.new
    end

    def cache_constants?
      @cache_constants
    end

    def use_standard_impl?
      @use_standard_impl
    end
  end
end

Mutations.cache_constants = true
Mutations.use_standard_impl = ENV['STANDARD_MUTATIONS']

require 'mutations/dry/init' unless Mutations.use_standard_impl?
