class SimpleCommand < Mutations::Command
  required do
    string :name, max_length: 10, matches: /\A\z/
    string :email, matches: /\A\w+@(\w+\.)+\w+\z/
    hash :properties do
      string :first_arg, matches: /\A\w+\z/
      hash :second_arg do
        integer :second_sub_arg, in: [42]
      end
    end
    integer :amount, in: [42]
  end

  schema do
    optional(:just_in_case).filled(:int?, included_in?: [42])
  end

  def validate
    #   add_error(:email, :invalid, 'Email must contain @') unless email && email.include?('@')
  end

  def execute
    inputs
  end
end

HI = {
  name: 'Aleksei Matiushkin',
  email: 'am@kantox.com',
  properties: {
    first_arg: 42,
    second_arg: {
      second_sub_arg: '0'
    }
  },
  amount: 0,
  just_in_case: 42
}.freeze
INST = SimpleCommand.schema.call(HI)
