# rubocop:disable Style/ClassAndModuleChildren
class Dry::Logic::Rule::Value < Dry::Logic::Rule
  def input
    predicate.args.last rescue nil
  end
end
# rubocop:enable Style/ClassAndModuleChildren
