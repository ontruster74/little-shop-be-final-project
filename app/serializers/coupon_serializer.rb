class CouponSerializer
  include JSONAPI::Serializer
  attributes :name, :code, :discount_type, :value, :activated, :merchant_id
end