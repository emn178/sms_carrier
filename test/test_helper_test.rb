# encoding: utf-8
require 'abstract_unit'

class TestHelperCarrier < SmsCarrier::Base
  def test
    @world = "Earth"
    sms body: render(inline: "Hello, <%= @world %>"),
      to: "+886912345678",
      from: "+886987654321"
  end
end

class TestHelperCarrierTest < SmsCarrier::TestCase
  def test_setup_sets_right_action_carrier_options
    assert_equal :test, SmsCarrier::Base.delivery_method
    assert SmsCarrier::Base.perform_deliveries
    assert_equal [], SmsCarrier::Base.deliveries
  end

  def test_setup_creates_the_expected_carrier
    assert_kind_of SmsCarrier::Sms, @expected
  end

  def test_carrier_class_is_correctly_inferred
    assert_equal TestHelperCarrier, self.class.carrier_class
  end

  def test_determine_default_carrier_raises_correct_error
    assert_raise(SmsCarrier::NonInferrableCarrierError) do
      self.class.determine_default_carrier("NotACarrierTest")
    end
  end

  def test_assert_smses
    assert_nothing_raised do
      assert_smses 1 do
        TestHelperCarrier.test.deliver_now
      end
    end
  end

  def test_repeated_assert_smses_calls
    assert_nothing_raised do
      assert_smses 1 do
        TestHelperCarrier.test.deliver_now
      end
    end

    assert_nothing_raised do
      assert_smses 2 do
        TestHelperCarrier.test.deliver_now
        TestHelperCarrier.test.deliver_now
      end
    end
  end

  def test_assert_smses_with_no_block
    assert_nothing_raised do
      TestHelperCarrier.test.deliver_now
      assert_smses 1
    end

    assert_nothing_raised do
      TestHelperCarrier.test.deliver_now
      TestHelperCarrier.test.deliver_now
      assert_smses 3
    end
  end

  def test_assert_no_smses
    assert_nothing_raised do
      assert_no_smses do
        TestHelperCarrier.test
      end
    end
  end

  def test_assert_smses_too_few_sent
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_smses 2 do
        TestHelperCarrier.test.deliver_now
      end
    end

    assert_match(/2 .* but 1/, error.message)
  end

  def test_assert_smses_too_many_sent
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_smses 1 do
        TestHelperCarrier.test.deliver_now
        TestHelperCarrier.test.deliver_now
      end
    end

    assert_match(/1 .* but 2/, error.message)
  end

  def test_assert_smses_message
    TestHelperCarrier.test.deliver_now
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_smses 2 do
        TestHelperCarrier.test.deliver_now
      end
    end
    assert_match "Expected: 2", error.message
    assert_match "Actual: 1", error.message
  end

  def test_assert_no_smses_failure
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_no_smses do
        TestHelperCarrier.test.deliver_now
      end
    end

    assert_match(/0 .* but 1/, error.message)
  end
end

class AnotherTestHelperCarrierTest < SmsCarrier::TestCase
  tests TestHelperCarrier

  def setup
    @test_var = "a value"
  end

  def test_setup_shouldnt_conflict_with_carrier_setup
    assert_kind_of SmsCarrier::Sms, @expected
    assert_equal 'a value', @test_var
  end
end
