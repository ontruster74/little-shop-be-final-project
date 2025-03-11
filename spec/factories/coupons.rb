FactoryBot.define do
  factory :coupon do
    name { Faker::Commerce.product_name }
    code { Faker::Alphanumeric.alphanumeric(number: 6).upcase }
    discount_type { ["percent", "dollar"].sample }
    value { Faker::Number.between(from: 0.10, to: 100.00) }
    activated { Faker::Boolean.boolean }
  end
end
