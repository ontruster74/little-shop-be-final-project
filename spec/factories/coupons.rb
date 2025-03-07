FactoryBot.define do
  factory :coupon do
    code { "MyString" }
    discount_type { "MyString" }
    value { 1 }
    activated { false }
    merchant { nil }
  end
end
