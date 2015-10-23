require 'abstract_unit'

class NullCarrier
  attr_accessor :settings

  def initialize(settings)
    self.settings = settings
  end

  def deliver!(sms)
  end
end
SmsCarrier::Base.add_delivery_method :null, NullCarrier

class MyCustomDelivery
end

class MyOptionedDelivery
  attr_reader :options
  def initialize(options)
    @options = options
  end
end

class BogusDelivery
  def initialize(*)
  end

  def deliver!(sms)
    raise "failed"
  end
end

class DefaultsDeliveryMethodsTest < ActiveSupport::TestCase
  test "default smtp settings" do
    settings = { }
    assert_equal settings, SmsCarrier::Base.test_settings
  end
end

class CustomDeliveryMethodsTest < ActiveSupport::TestCase
  setup do
    @old_delivery_method = SmsCarrier::Base.delivery_method
    SmsCarrier::Base.add_delivery_method :custom, MyCustomDelivery
  end

  teardown do
    SmsCarrier::Base.delivery_method = @old_delivery_method
    new = SmsCarrier::Base.delivery_methods.dup
    new.delete(:custom)
    SmsCarrier::Base.delivery_methods = new
  end

  test "allow to add custom delivery method" do
    SmsCarrier::Base.delivery_method = :custom
    assert_equal :custom, SmsCarrier::Base.delivery_method
  end

  test "allow to customize custom settings" do
    SmsCarrier::Base.custom_settings = { foo: :bar }
    assert_equal Hash[foo: :bar], SmsCarrier::Base.custom_settings
  end

  test "respond to custom settings" do
    assert_respond_to SmsCarrier::Base, :custom_settings
    assert_respond_to SmsCarrier::Base, :custom_settings=
  end

  test "does not respond to unknown settings" do
    assert_raise NoMethodError do
      SmsCarrier::Base.another_settings
    end
  end
end

class SmsDeliveryTest < ActiveSupport::TestCase
  class DeliveryCarrier < SmsCarrier::Base
    DEFAULT_HEADERS = {
      to: '+886987654321',
      from: '+886912345678'
    }

    def welcome(hash={})
      sms(DEFAULT_HEADERS.merge(hash))
    end
  end

  setup do
    @old_delivery_method = DeliveryCarrier.delivery_method
  end

  teardown do
    DeliveryCarrier.delivery_method = @old_delivery_method
    DeliveryCarrier.deliveries.clear
  end

  test "ActionMailer should be told when Mail gets delivered" do
    DeliveryCarrier.expects(:deliver_sms).once
    DeliveryCarrier.welcome.deliver_now
  end

  test "delivery method can be customized per instance" do
    SmsCarrier::TestCarrier.any_instance.expects(:deliver!)
    email = DeliveryCarrier.welcome.deliver_now
    assert_instance_of SmsCarrier::TestCarrier, email.delivery_method
    email = DeliveryCarrier.welcome(delivery_method: :null).deliver_now
    assert_instance_of NullCarrier, email.delivery_method
  end

  test "delivery method can be customized in subclasses not changing the parent" do
    DeliveryCarrier.delivery_method = :null
    assert_equal :test, SmsCarrier::Base.delivery_method
    sms_instance = DeliveryCarrier.welcome.deliver_now
    assert_instance_of NullCarrier, sms_instance.delivery_method
  end

  test "delivery method options default to class level options" do
    default_options = {a: "b"}
    SmsCarrier::Base.add_delivery_method :optioned, MyOptionedDelivery, default_options
    sms_instance = DeliveryCarrier.welcome(delivery_method: :optioned)
    assert_equal default_options, sms_instance.delivery_method.options
  end

  test "delivery method options can be overridden per mail instance" do
    default_options = {a: "b"}
    SmsCarrier::Base.add_delivery_method :optioned, MyOptionedDelivery, default_options
    overridden_options = {a: "a"}
    sms_instance = DeliveryCarrier.welcome(delivery_method: :optioned, delivery_method_options: overridden_options)
    assert_equal overridden_options, sms_instance.delivery_method.options
  end

  test "default delivery options can be overridden per mail instance" do
    settings = {
    }
    assert_equal settings, SmsCarrier::Base.test_settings
    overridden_options = {user_name: "overridden", password: "somethingobtuse"}
    sms_instance = DeliveryCarrier.welcome(delivery_method_options: overridden_options)
    delivery_method_instance = sms_instance.delivery_method
    assert_equal "overridden", delivery_method_instance.settings[:user_name]
    assert_equal "somethingobtuse", delivery_method_instance.settings[:password]
    assert_equal delivery_method_instance.settings.merge(overridden_options), delivery_method_instance.settings

    # make sure that overriding delivery method options per mail instance doesn't affect the Base setting
    assert_equal settings, SmsCarrier::Base.test_settings
  end

  test "non registered delivery methods raises errors" do
    DeliveryCarrier.delivery_method = :unknown
    error = assert_raise RuntimeError do
      DeliveryCarrier.welcome.deliver_now
    end
    assert_equal "Invalid delivery method :unknown", error.message
  end

  test "undefined delivery methods raises errors" do
    DeliveryCarrier.delivery_method = nil
    error = assert_raise RuntimeError do
      DeliveryCarrier.welcome.deliver_now
    end
    assert_equal "Delivery method cannot be nil", error.message
  end

  test "does not perform deliveries if requested" do
    old_perform_deliveries = DeliveryCarrier.perform_deliveries
    begin
      DeliveryCarrier.perform_deliveries = false
      SmsCarrier::Sms.any_instance.expects(:deliver!).never
      DeliveryCarrier.welcome.deliver_now
    ensure
      DeliveryCarrier.perform_deliveries = old_perform_deliveries
    end
  end

  test "does not append the deliveries collection if told not to perform the delivery" do
    old_perform_deliveries = DeliveryCarrier.perform_deliveries
    begin
      DeliveryCarrier.perform_deliveries = false
      DeliveryCarrier.welcome.deliver_now
      assert_equal [], DeliveryCarrier.deliveries
    ensure
      DeliveryCarrier.perform_deliveries = old_perform_deliveries
    end
  end

  test "raise errors on bogus deliveries" do
    DeliveryCarrier.delivery_method = BogusDelivery
    assert_raise RuntimeError do
      DeliveryCarrier.welcome.deliver_now
    end
  end

  test "does not increment the deliveries collection on error" do
    DeliveryCarrier.delivery_method = BogusDelivery
    assert_raise RuntimeError do
      DeliveryCarrier.welcome.deliver_now
    end
    assert_equal [], DeliveryCarrier.deliveries
  end

  test "does not raise errors on bogus deliveries if set" do
    old_raise_delivery_errors = DeliveryCarrier.raise_delivery_errors
    begin
      DeliveryCarrier.delivery_method = BogusDelivery
      DeliveryCarrier.raise_delivery_errors = false
      assert_nothing_raised do
        DeliveryCarrier.welcome.deliver_now
      end
    ensure
      DeliveryCarrier.raise_delivery_errors = old_raise_delivery_errors
    end
  end

  test "does not increment the deliveries collection on bogus deliveries" do
    old_raise_delivery_errors = DeliveryCarrier.raise_delivery_errors
    begin
      DeliveryCarrier.delivery_method = BogusDelivery
      DeliveryCarrier.raise_delivery_errors = false
      DeliveryCarrier.welcome.deliver_now
      assert_equal [], DeliveryCarrier.deliveries
    ensure
      DeliveryCarrier.raise_delivery_errors = old_raise_delivery_errors
    end
  end
end
