require 'rails_helper'

RSpec.describe Coupon, type: :model do
  describe 'validations' do
    it { should validate_presence_of :name }

    it { should validate_presence_of :code }
    it 'should validate uniqueness of :code attribute' do
      merchant1 = create(:merchant, name: "Lorem Ipsum Inc.")
      merchant2 = create(:merchant, name: "Dolor Sit Amet Co.")

      coupon1 = create(:coupon, code: 'BOGO050', merchant_id: merchant1.id)
      coupon2 = Coupon.new(name: "Sample Name", code: 'BOGO050', discount_type: 'percent', value: 0.50, activated: true, merchant_id: merchant2.id)

      expect(coupon2).not_to be_valid
      expect(coupon2.errors[:code]).to include('Another coupon already has this code. Please ensure all coupon codes entered are unique.')
    end

    it { should validate_presence_of :value }
    it { should validate_numericality_of(:value).is_greater_than(0)}

    it { should validate_inclusion_of(:discount_type).in_array(['percent', 'dollar']) }

    context ':activated attribute validations' do
      it 'throws error if :activated = true and merchant already has 5+ activated coupons' do
        merchant = create(:merchant, name: "ACME Corp.")
        5.times {create(:coupon, merchant_id: merchant.id, activated: true) }

        sixth_coupon = Coupon.new(merchant_id: merchant.id, activated: true)
        
        expect(sixth_coupon).not_to be_valid
        expect(sixth_coupon.errors.first.attribute.to_s).to eq("activated")
        expect(sixth_coupon.errors.first.type).to eq("A merchant cannot have more than 5 coupons activated at a time.")
      end

      it 'allows :activated = true if merchant has less than 5 active coupons' do
        merchant = create(:merchant, name: "ACME Corp.")
        3.times {create(:coupon, merchant_id: merchant.id, activated: true) }

        new_coupon = create(:coupon, merchant_id: merchant.id, activated: true)
        
        expect(new_coupon).to be_valid
      end

      it 'allows :activated = false' do
        merchant = create(:merchant, name: "ACME Corp.")
        5.times {create(:coupon, merchant_id: merchant.id, activated: true) }

        new_coupon = create(:coupon, merchant_id: merchant.id, activated: false)
        
        expect(new_coupon).to be_valid
      end

    end
  end

  describe 'relationships' do
    it { should belong_to :merchant }
    it { should have_many :invoices }
  end
end
