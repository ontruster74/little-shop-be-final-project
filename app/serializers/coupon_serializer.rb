class CouponSerializer
  include JSONAPI::Serializer
  attributes :code, :discount_type, :value, :activated, :merchant_id
end