class Api::V1::Merchants::CouponsController < ApplicationController
  before_action :set_merchant
  before_action :set_coupon, only: [:show, :update]
    def index
      if params[:activation].present?
        coupons_list = @merchant.coupons_filtered_by_activation(params[:activation])
      else 
        coupons_list = @merchant.coupons
      end

      render json: CouponSerializer.new(coupons_list)
    end
  
    def show
      render json: CouponSerializer.new(@coupon, { params: {action: 'show'} })
    end
  
    def create
      new_coupon = Coupon.create!(coupon_params) # safe to use create! here because our exception handler will gracefully handle exception
      render json: CouponSerializer.new(new_coupon), status: :created
    end
  
    def update
      @coupon.update!(coupon_params)
      render json: CouponSerializer.new(@coupon), status: :ok
    end
  
    private
  
    def coupon_params
      params.permit(:name, :code, :discount_type, :value, :activated, :merchant_id)
    end

    def set_merchant
      @merchant = Merchant.find(params[:merchant_id])
    end

    def set_coupon
      @coupon = @merchant.coupons.find(params[:id])
    end
end
