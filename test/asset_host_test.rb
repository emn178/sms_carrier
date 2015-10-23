require 'abstract_unit'
require 'action_controller'

class AssetHostCarrier < SmsCarrier::Base
  def sms_with_asset
    sms to: '+886987654321', from: '+886912345678'
  end
end

class AssetHostTest < SmsCarrier::TestCase
  def setup
    AssetHostCarrier.configure do |c|
      c.asset_host = "http://www.example.com"
    end
  end

  def teardown
    restore_delivery_method
  end

  def test_asset_host_as_string
    sms = AssetHostCarrier.sms_with_asset
    assert_equal 'http://www.example.com/images/somelogo.png', sms.body.to_s.strip
  end

  def test_asset_host_as_one_argument_proc
    AssetHostCarrier.config.asset_host = Proc.new { |source|
      if source.starts_with?('/images')
        'http://images.example.com'
      end
    }
    sms = AssetHostCarrier.sms_with_asset
    assert_equal 'http://images.example.com/images/somelogo.png', sms.body.to_s.strip
  end
end
