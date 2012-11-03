class Product
  include Mongoid::Document
  include MongoidMapReduceHelper::Helper

  field :name, type: String
  field :price, type: BigDecimal
end