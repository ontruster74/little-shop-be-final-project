class CouponSerializer
  include JSONAPI::Serializer
  attributes :name, :code, :discount_type, :value, :activated, :merchant_id, :times_used

  attribute :times_used, if: ->(coupon, params) { params[:action] == 'show'} do |coupon|
    coupon.invoices.count
  end
end