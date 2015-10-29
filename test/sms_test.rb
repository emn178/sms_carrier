require 'abstract_unit'

class SmsTest < SmsCarrier::TestCase
  def test_body_assign
    sms = SmsCarrier::Sms.new
    sms[:body] = 'body'
    assert_equal 'body', sms.body
  end
end
