class SimpleCommand < Mutations::Command
  required do
    string :name, max_length: 10
    string :email, matches: /\A\w+@(\w+\.)+\w+\z/
    hash :properties do
      string :first, matches: /\A\w+\z/
      integer :second
    end
  end

  optional do
    integer :amount, in: [42]
  end

  def validate
  #   add_error(:email, :invalid, 'Email must contain @') unless email && email.include?('@')
  end

  def execute
    inputs
  end
end
