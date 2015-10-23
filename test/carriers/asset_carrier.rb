class AssetCarrier < SmsCarrier::Base
  self.carrier_name = "asset_carrier"

  def welcome
   sms
  end
end
