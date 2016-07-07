require 'mutations'

class SimpleCommand < Mutations::Command
  required do
    string :name, max_length: 10, matches: /\A\z/
    string :email, matches: /\A\w+@(\w+\.)+\w+\z/
    string :to_be_stripped
    hash :properties do
      string :first_arg, matches: /\A\w+\z/
      hash :second_arg do
        integer :second_sub_arg, in: [42]
      end
    end
    integer :amount, in: [42]
  end

  def validate
    #   add_error(:email, :invalid, 'Email must contain @') unless email && email.include?('@')
  end

  def execute
    inputs
  end
end

class CommandWithArrayInput < Mutations::Command
  required do
    string :name, max_length: 10, matches: /\A\z/
    array :emails do
      string :email
      string :type
    end
  end
end

class CommandWithAnonymousArrayInput < Mutations::Command
  required do
    string :name, max_length: 10, matches: /\A\z/
    array :emails do
      string
    end
  end
end

class ExtendedCommand < SimpleCommand
  schema do
    optional(:ext_param).filled(:int?, included_in?: [42])
  end
end

class ReExtendedCommand < ExtendedCommand
  schema do
    optional(:ext_ext_param).filled(:int?, included_in?: [42])
  end
end

HI = {
  name: 'Aleksei Matiushkin',
  email: 'am@kantox.com',
  to_be_stripped: '    o_o      ',
  properties: {
    first_arg: 42,
    second_arg: {
      second_sub_arg: '0'
    }
  },
  amount: 0,
  to_be_filtered: 42,
  ext_param: 42,
  ext_ext_param: 42
}.freeze
INST = SimpleCommand.schema.call(HI)
