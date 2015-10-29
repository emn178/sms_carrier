# encoding: utf-8
require 'abstract_unit'
require 'set'

require 'action_dispatch'
require 'active_support/time'

require 'carriers/base_carrier'
require 'carriers/proc_carrier'
require 'carriers/asset_carrier'

class BaseTest < ActiveSupport::TestCase
  setup do
    @original_delivery_method = SmsCarrier::Base.delivery_method
    SmsCarrier::Base.delivery_method = :test
    @original_asset_host = SmsCarrier::Base.asset_host
    @original_assets_dir = SmsCarrier::Base.assets_dir
  end

  teardown do
    SmsCarrier::Base.asset_host = @original_asset_host
    SmsCarrier::Base.assets_dir = @original_assets_dir
    BaseCarrier.deliveries.clear
    SmsCarrier::Base.delivery_method = @original_delivery_method
  end

  test "method call to sms does not raise error" do
    assert_nothing_raised { BaseCarrier.welcome }
  end

  # Basic sms usage without block
  test "sms() should set the options of the SMS message" do
    sms = BaseCarrier.welcome
    assert_equal(['+886912345678'],    sms.to)
    assert_equal('+886987654321', sms.from)
    assert_equal('Welcome',   sms.body)
  end

  test "sms() with from overwrites the class level default" do
    sms = BaseCarrier.welcome(from: '+886987654321',
                               to:   '+886912345678')
    assert_equal('+886987654321', sms.from)
    assert_equal(['+886912345678'], sms.to)
  end

  test "sms() renders the template using the method being processed" do
    sms = BaseCarrier.welcome
    assert_equal("Welcome", sms.body)
  end

  test "can pass in :body to the SMS method hash" do
    sms = BaseCarrier.welcome(body: "Hello there")
    assert_equal("Hello there", sms.body)
  end

  # Custom options
  test "custom options" do
    sms = BaseCarrier.welcome
    assert_equal("Not SPAM", sms['X-SPAM'])
  end

  test "can pass random options in as a hash to SMS" do
    hash = {'X-Special-Domain-Specific-Header' => "SecretValue",
            'In-Reply-To' => '1234@mikel.me.com' }
    sms = BaseCarrier.welcome(hash)
    assert_equal('SecretValue', sms['X-Special-Domain-Specific-Header'])
    assert_equal('1234@mikel.me.com', sms['In-Reply-To'])
  end

  test "can pass random options in as a hash to options" do
    hash = {'X-Special-Domain-Specific-Header' => "SecretValue",
            'In-Reply-To' => '1234@mikel.me.com' }
    sms = BaseCarrier.welcome_with_options(hash)
    assert_equal('SecretValue', sms['X-Special-Domain-Specific-Header'])
    assert_equal('1234@mikel.me.com', sms['In-Reply-To'])
  end

  # Defaults values
  test "uses random default options from class" do
    with_default BaseCarrier, "X-Custom" => "Custom" do
      sms = BaseCarrier.welcome
      assert_equal("Custom", sms["X-Custom"])
    end
  end

  # Class level API with method missing
  test "should respond to action methods" do
    assert_respond_to BaseCarrier, :welcome
    assert !BaseCarrier.respond_to?(:sms)
    assert !BaseCarrier.respond_to?(:options)
  end

  test "calling just the action should return the generated SMS object" do
    sms = BaseCarrier.welcome
    assert_equal(0, BaseCarrier.deliveries.length)
    assert_equal('Welcome', sms.body)
  end

  test "calling deliver on the action should deliver the SMS object" do
    BaseCarrier.expects(:deliver_sms).once
    sms = BaseCarrier.welcome.deliver_now
    assert_equal 'Welcome', sms.body
  end

  test "calling deliver on the action should increment the deliveries collection if using the test carrier" do
    BaseCarrier.welcome.deliver_now
    assert_equal(1, BaseCarrier.deliveries.length)
  end

  test "calling deliver, SmsCarrier should yield back to SMS to let it call :do_delivery on itself" do
    sms = SmsCarrier::Sms.new
    sms.expects(:do_delivery).once
    BaseCarrier.expects(:welcome).returns(sms)
    BaseCarrier.welcome.deliver
  end

  # Rendering
  test "should raise if missing template in implicit render" do
    assert_raises ActionView::MissingTemplate do
      BaseCarrier.implicit_different_template('missing_template').deliver_now
    end
    assert_equal(0, BaseCarrier.deliveries.length)
  end

  test "you can specify the template path for implicit lookup" do
    sms = BaseCarrier.welcome_from_another_path('another.path/base_carrier').deliver_now
    assert_equal("Welcome from another path", sms.body)

    sms = BaseCarrier.welcome_from_another_path(['unknown/invalid', 'another.path/base_carrier']).deliver_now
    assert_equal("Welcome from another path", sms.body)
  end

  test "assets tags should use SmsCarrier's asset_host settings" do
    SmsCarrier::Base.config.asset_host = "http://global.com"
    SmsCarrier::Base.config.assets_dir = "global/"

    sms = AssetCarrier.welcome

    assert_equal("http://global.com/images/dummy.png", sms.body.to_s.strip)
  end

  test "assets tags should use a Carrier's asset_host settings when available" do
    SmsCarrier::Base.config.asset_host = "http://global.com"
    SmsCarrier::Base.config.assets_dir = "global/"

    TempAssetCarrier = Class.new(AssetCarrier) do
      self.carrier_name = "asset_carrier"
      self.asset_host = "http://local.com"
    end

    sms = TempAssetCarrier.welcome

    assert_equal("http://local.com/images/dummy.png", sms.body.to_s.strip)
  end

  test 'the view is not rendered when SMS was never called' do
    sms = BaseCarrier.without_sms_call
    assert_equal('', sms.body.to_s.strip)
    sms.deliver_now
  end

  test 'the return value of carrier methods is not relevant' do
    sms = BaseCarrier.with_nil_as_return_value
    assert_equal('Welcome', sms.body.to_s.strip)
    sms.deliver_now
  end

  # Before and After hooks

  class MyObserver
    def self.delivered_sms(sms)
    end
  end

  class MySecondObserver
    def self.delivered_sms(sms)
    end
  end

  test "you can register an observer to the sms object that gets informed on SMS delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_observer(MyObserver)
      sms = BaseCarrier.welcome
      MyObserver.expects(:delivered_sms).with(sms)
      sms.deliver_now
    end
  end

  test "you can register an observer using its stringified name to the sms object that gets informed on SMS delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_observer("BaseTest::MyObserver")
      sms = BaseCarrier.welcome
      MyObserver.expects(:delivered_sms).with(sms)
      sms.deliver_now
    end
  end

  test "you can register an observer using its symbolized underscored name to the sms object that gets informed on SMS delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_observer(:"base_test/my_observer")
      sms = BaseCarrier.welcome
      MyObserver.expects(:delivered_sms).with(sms)
      sms.deliver_now
    end
  end

  test "you can register multiple observers to the sms object that both get informed on SMS delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_observers("BaseTest::MyObserver", MySecondObserver)
      sms = BaseCarrier.welcome
      MyObserver.expects(:delivered_sms).with(sms)
      MySecondObserver.expects(:delivered_sms).with(sms)
      sms.deliver_now
    end
  end

  class MyInterceptor
    def self.delivering_sms(sms); end
  end

  class MySecondInterceptor
    def self.delivering_sms(sms); end
  end

  test "you can register an interceptor to the sms object that gets passed the sms object before delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_interceptor(MyInterceptor)
      sms = BaseCarrier.welcome
      MyInterceptor.expects(:delivering_sms).with(sms)
      sms.deliver_now
    end
  end

  test "you can register an interceptor using its stringified name to the sms object that gets passed the sms object before delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_interceptor("BaseTest::MyInterceptor")
      sms = BaseCarrier.welcome
      MyInterceptor.expects(:delivering_sms).with(sms)
      sms.deliver_now
    end
  end

  test "you can register an interceptor using its symbolized underscored name to the sms object that gets passed the sms object before delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_interceptor(:"base_test/my_interceptor")
      sms = BaseCarrier.welcome
      MyInterceptor.expects(:delivering_sms).with(sms)
      sms.deliver_now
    end
  end

  test "you can register multiple interceptors to the sms object that both get passed the sms object before delivery" do
    sms_side_effects do
      SmsCarrier::Base.register_interceptors("BaseTest::MyInterceptor", MySecondInterceptor)
      sms = BaseCarrier.welcome
      MyInterceptor.expects(:delivering_sms).with(sms)
      MySecondInterceptor.expects(:delivering_sms).with(sms)
      sms.deliver_now
    end
  end

  test "being able to put proc's into the defaults hash and they get evaluated on sms sending" do
    sms1 = ProcCarrier.welcome['X-Proc-Method']
    yesterday = 1.day.ago
    Time.stubs(:now).returns(yesterday)
    sms2 = ProcCarrier.welcome['X-Proc-Method']
    assert(sms1.to_s.to_i > sms2.to_s.to_i)
  end

  test 'default values which have to_proc (e.g. symbols) should not be considered procs' do
    assert(ProcCarrier.welcome['x-has-to-proc'].to_s == 'symbol')
  end

  test "we can call other defined methods on the class as needed" do
    sms = ProcCarrier.welcome
    assert_equal("Thanks for signing up this afternoon", sms.body)
  end

  test "modifying the SMS message with a before_action" do
    class BeforeActionCarrier < SmsCarrier::Base
      before_action :add_special_header!

      def welcome ; sms ; end

      private
      def add_special_header!
        options('X-Special-Header' => 'Wow, so special')
      end
    end

    assert_equal('Wow, so special', BeforeActionCarrier.welcome['X-Special-Header'].to_s)
  end

  test "modifying the SMS message with an after_action" do
    class AfterActionCarrier < SmsCarrier::Base
      after_action :add_special_header!

      def welcome ; sms ; end

      private
      def add_special_header!
        options('X-Special-Header' => 'Testing')
      end
    end

    assert_equal('Testing', AfterActionCarrier.welcome['X-Special-Header'].to_s)
  end

  test "action methods should be refreshed after defining new method" do
    class FooCarrier < SmsCarrier::Base
      # this triggers action_methods
      self.respond_to?(:foo)

      def notify
      end
    end

    assert_equal Set.new(["notify"]), FooCarrier.action_methods
  end

  test "carrier can be anonymous" do
    carrier = Class.new(SmsCarrier::Base) do
      def welcome
        sms
      end
    end

    assert_equal "anonymous", carrier.carrier_name

    assert_equal "Anonymous carrier body\n", carrier.welcome.body
  end

  test "default_from can be set" do
    class DefaultFromCarrier < SmsCarrier::Base
      default to: '+88612345678'
      self.default_options = {from: "+886987654321"}

      def welcome
        sms(body: "hello world")
      end
    end

    assert_equal "+886987654321", DefaultFromCarrier.welcome.from
  end

  test "sms() without arguments serves as getter for the current SMS message" do
    class CarrierWithCallback < SmsCarrier::Base
      after_action :a_callback

      def welcome
        options('X-Special-Header' => 'special indeed!')
        sms body: "hello world", to: ["+886912345678"]
      end

      def a_callback
        sms.to << "+886963852741"
      end
    end

    sms = CarrierWithCallback.welcome
    assert_equal ["+886912345678", "+886963852741"], sms.to
    assert_equal "X-Special-Header: special indeed!\nFrom: \nTo: [\"+886912345678\", \"+886963852741\"]\nBody: hello world\n", sms.to_s
    assert_equal "special indeed!", sms["X-Special-Header"].to_s
  end

  test "carrier should get carrier_name" do
    sms = BaseCarrier.test_carrier_name
    assert_equal "base_carrier", sms.options[:carrier_name]
  end

  protected

    # Execute the block setting the given values and restoring old values after
    # the block is executed.
    def swap(klass, new_values)
      old_values = {}
      new_values.each do |key, value|
        old_values[key] = klass.send key
        klass.send :"#{key}=", value
      end
      yield
    ensure
      old_values.each do |key, value|
        klass.send :"#{key}=", value
      end
    end

    def with_default(klass, new_values)
      old = klass.default_params
      klass.default(new_values)
      yield
    ensure
      klass.default_params = old
    end

    # A simple hack to restore the observers and interceptors for Mail, as it
    # does not have an unregister API yet.
    def sms_side_effects
      old_observers = SmsCarrier::Sms.class_variable_get(:@@delivery_notification_observers)
      old_delivery_interceptors = SmsCarrier::Sms.class_variable_get(:@@delivery_interceptors)
      yield
    ensure
      SmsCarrier::Sms.class_variable_set(:@@delivery_notification_observers, old_observers)
      SmsCarrier::Sms.class_variable_set(:@@delivery_interceptors, old_delivery_interceptors)
    end

    def with_translation(locale, data)
      I18n.backend.store_translations(locale, data)
      yield
    ensure
      I18n.backend.reload!
    end
end
