require 'abstract_unit'

class TestCarrierTest < SmsCarrier::TestCase
  def test_deliveries
    deliveries = SmsCarrier::TestCarrier.deliveries
    SmsCarrier::TestCarrier.deliveries = [1]
    assert_equal 1, SmsCarrier::TestCarrier.deliveries.length
    SmsCarrier::TestCarrier.deliveries = deliveries
  end
end
