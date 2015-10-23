class DelayedCarrier < SmsCarrier::Base

  def test_message(*)
    sms(from: '+886987654321', to: '+886912345678', body: 'Test Body')
  end
end
