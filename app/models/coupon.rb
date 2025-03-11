class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validate :merchant_5_coupon_limit, on: [:create, :update]

  validates_presence_of(:name)
  validates :code, presence: true, uniqueness: {message: 'Another coupon already has this code. Please ensure all coupon codes entered are unique.'}
  validates :discount_type, presence: true, inclusion: { in: ['percent', 'dollar']}
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :activated, inclusion: { in: [true, false] }

  private

  def merchant_5_coupon_limit
    if activated && merchant.coupons.where(activated: true).count >= 5
      errors.add(:activated, "A merchant cannot have more than 5 coupons activated at a time.")
    end
  end
end
