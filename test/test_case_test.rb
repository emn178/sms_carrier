require 'abstract_unit'

class TestTestCarrier < SmsCarrier::Base
end

class CrazyNameCarrierTest < SmsCarrier::TestCase
  tests TestTestCarrier

  def test_set_carrier_class_manual
    assert_equal TestTestCarrier, self.class.carrier_class
  end
end

class CrazySymbolNameCarrierTest < SmsCarrier::TestCase
  tests :test_test_carrier

  def test_set_carrier_class_manual_using_symbol
    assert_equal TestTestCarrier, self.class.carrier_class
  end
end

class CrazyStringNameCarrierTest < SmsCarrier::TestCase
  tests 'test_test_carrier'

  def test_set_carrier_class_manual_using_string
    assert_equal TestTestCarrier, self.class.carrier_class
  end
end

class CrazyNilCarrierTest < SmsCarrier::TestCase
  begin
    tests nil 
  rescue => e
    @@error = e
  end

  def test_set_carrier_class_manual_using_nil
    assert_equal SmsCarrier::NonInferrableCarrierError, @@error.class
  end
end
