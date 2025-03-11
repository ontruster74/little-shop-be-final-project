require "rails_helper"

describe "Coupon endpoints", :type => :request do
  describe "Get all coupons" do
    it "should return all coupons for a given merchant" do
      merchant1 = create(:merchant)
      coupon1 = create(:coupon, merchant_id: merchant1.id)
      coupon2 = create(:coupon, merchant_id: merchant1.id)
      coupon3 = create(:coupon, merchant_id: merchant1.id)
      merchant2 = create(:merchant)
      create(:coupon, merchant_id: merchant2.id)
  
      get "/api/v1/merchants/#{merchant1.id}/coupons"
  
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(response).to be_successful
      expect(json[:data].count).to eq(3)
      expect(json[:data][0][:id]).to eq(coupon1.id.to_s)
      expect(json[:data][1][:id]).to eq(coupon2.id.to_s)
      expect(json[:data][2][:id]).to eq(coupon3.id.to_s)
    end
  
    it "should return 404 and error message when merchant is not found" do
      get "/api/v1/merchants/100000/coupons"
  
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(response).to have_http_status(:not_found)
      expect(json[:message]).to eq("Your query could not be completed")
      expect(json[:errors]).to be_a Array
      expect(json[:errors].first).to eq("Couldn't find Merchant with 'id'=100000")
    end

    it "should be able to filter returned coupons by activation status based on query param" do
      merchant1 = create(:merchant, name: "Merchant1")
      merchant2  = create(:merchant, name: "Merchant2")
      
      create(:coupon, activated: "true", merchant_id: merchant1.id)
      create(:coupon, activated: "false", merchant_id: merchant1.id)
      create(:coupon, activated: "true", merchant_id: merchant2.id)
      create(:coupon, activated: "false", merchant_id: merchant2.id)

      get "/api/v1/merchants/#{merchant1.id}/coupons?activation=true"
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)
      expect(json[:data].count).to eq(1)
      expect(json[:data][0][:attributes][:merchant_id]).to eq(merchant1.id)
    end
  end

  describe "get a merchant coupon by id" do
    it "should return a single coupon with the correct id" do
      merchant = create(:merchant, name: "Joe & Sons")
      coupon1 = create(:coupon, merchant_id: merchant.id)

      get "/api/v1/merchants/#{merchant.id}/coupons/#{coupon1.id}"
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)

      expect(json[:data]).to include(:id, :type, :attributes)
      expect(json[:data][:id]).to eq(coupon1.id.to_s)
      expect(json[:data][:type]).to eq("coupon")

      expect(json[:data][:attributes][:name]).to be_a(String)
      expect(json[:data][:attributes][:code]).to be_a(String)
      expect(json[:data][:attributes][:discount_type]).to be_a(String)
      expect(json[:data][:attributes][:value]).to be_a(Float)
      expect(json[:data][:attributes][:times_used]).to eq(0)
      expect([true, false]).to include(json[:data][:attributes][:activated])
      expect(json[:data][:attributes][:merchant_id]).to eq(merchant.id)
    end

    it "should include the number of invoices a coupon is applied to as an attribute" do
      merchant = create(:merchant)
      customer = create(:customer)
      coupon = create(:coupon, merchant_id: merchant.id)

      invoice1 = create(:invoice, customer: customer, merchant: merchant, coupon_id: coupon.id)
      invoice2 = create(:invoice, customer: customer, merchant: merchant, coupon_id: coupon.id)
      invoice3 = create(:invoice, customer: customer, merchant: merchant, coupon_id: coupon.id)

      get "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}"
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)

      expect(json[:data]).to include(:id, :type, :attributes)
      expect(json[:data][:attributes]).to include(:times_used)
      expect(json[:data][:attributes][:times_used]).to eq(3)
    end

    it "should return 404 and error message when coupon is not found" do
      merchant = create(:merchant, name: "Joe & Sons")

      get "/api/v1/merchants/#{merchant.id}/coupons/1"
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:not_found)
      expect(json[:message]).to eq("Your query could not be completed")
      expect(json[:errors]).to be_a Array
      expect(json[:errors].first).to eq("Couldn't find Coupon with 'id'=1 [WHERE \"coupons\".\"merchant_id\" = $1]")
    end
  end

  describe "create a coupon" do
    it "should successfully create a coupon when all fields are present" do
      merchant = create(:merchant, name: "Mumford and Sons")

      name = "Buy One Get One 50% Off"
      code = "BOGO050"
      discount_type = "percent"
      value = 0.50
      activated = true

      body = {
        name: name,
        code: code,
        discount_type: discount_type,
        value: value,
        activated: activated,
        merchant_id: merchant.id
      }

      post "/api/v1/merchants/#{merchant.id}/coupons", params: body, as: :json
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:created)

      expect(json[:data]).to include(:id, :type, :attributes)
      expect(json[:data][:id]).to be_a(String)
      expect(json[:data][:type]).to eq("coupon")

      expect(json[:data][:attributes][:name]).to eq(name)
      expect(json[:data][:attributes][:code]).to eq(code)
      expect(json[:data][:attributes][:discount_type]).to eq(discount_type)
      expect(json[:data][:attributes][:value]).to eq(value)
      expect(json[:data][:attributes][:activated]).to eq(activated)
      expect(json[:data][:attributes][:merchant_id]).to eq(merchant.id)
    end

    it "should display an error message if fields are missing" do
      merchant = create(:merchant, name: "Paper Street Soap Company")

      post "/api/v1/merchants/#{merchant.id}/coupons", params: {}, as: :json
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:errors].first).to eq("Validation failed: Name can't be blank, Code can't be blank, Discount type can't be blank, Discount type is not included in the list, Value can't be blank, Value is not a number, Activated is not included in the list")
    end

    context "sad paths" do
      it "should throw an error if created coupon code is not unique" do
        merchant1 = create(:merchant, name: "Lorem Ipsum Inc.")
        merchant2 = create(:merchant, name: "Dolor Sit Amet Co.")

        coupon1 = create(:coupon, code: 'BOGO050', merchant_id: merchant1.id)
        coupon2 = Coupon.new(name: "Sample Name", code: 'BOGO050', discount_type: 'percent', value: 0.50, activated: true, merchant_id: merchant2.id)

        expect(coupon2).not_to be_valid
        expect(coupon2.errors[:code]).to include('Another coupon already has this code. Please ensure all coupon codes entered are unique.')
      end

      it "should throw an error if created coupon brings merchant active coupon total above 5" do
        merchant = create(:merchant, name: "ACME Corp.")
        5.times {create(:coupon, merchant_id: merchant.id, activated: true) }

        sixth_coupon = Coupon.new(merchant_id: merchant.id, activated: true)
        
        expect(sixth_coupon).not_to be_valid
        expect(sixth_coupon.errors.first.attribute.to_s).to eq("activated")
        expect(sixth_coupon.errors.first.type).to eq("A merchant cannot have more than 5 coupons activated at a time.")
      end
    end

  end

  describe "Update coupon" do
    it "should properly update an existing coupon" do
      merchant = create(:merchant, name: "Allman Brothers Co.")
      coupon = create(:coupon, name: "Lorem Ipsum", merchant_id: merchant.id)\

      new_name = "Dolor Sit Amet"

      body = {
        name: new_name
      }

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params: body, as: :json
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)
      expect(json[:data][:attributes][:name]).to eq(new_name)
      expect(Coupon.find(coupon.id).name).to eq(new_name)
    end

    it "should be able to activate an inactive coupon" do
      merchant = create(:merchant, name: "Allman Brothers Co.")
      coupon = create(:coupon, activated: false, merchant_id: merchant.id)\

      body = {
        activated: true
      }

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params: body, as: :json
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)
      expect(json[:data][:attributes][:activated]).to eq(true)
      expect(Coupon.find(coupon.id).activated).to eq(true)
    end

    it "should be able to deactivate an active coupon" do
      merchant = create(:merchant, name: "Allman Brothers Co.")
      coupon = create(:coupon, activated: true, merchant_id: merchant.id)

      body = {
        activated: false
      }

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params: body, as: :json
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)
      expect(json[:data][:attributes][:activated]).to eq(false)
      expect(Coupon.find(coupon.id).activated).to eq(false)
    end

    it "should return 404 when coupon is not found" do
      merchant = create(:merchant, name: "Allman Brothers Co.")

      body = {
        name: "Dolor Sit Amet"
      }

      patch "/api/v1/merchants/#{merchant.id}/coupons/1", params: body, as: :json
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:not_found)
      expect(json[:errors].first).to eq("Couldn't find Coupon with 'id'=1 [WHERE \"coupons\".\"merchant_id\" = $1]")
    end
  end

  describe "sad paths" do
    it "should throw an error if updated coupon code is not unique" do
      
    end

    it "should throw an error if activating a coupon brings merchant active coupon total above 5" do
      
    end
  end

end