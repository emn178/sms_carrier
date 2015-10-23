require 'abstract_unit'
require 'carriers/base_carrier'
require 'active_support/log_subscriber/test_helper'
require 'sms_carrier/log_subscriber'

class AMLogSubscriberTest < SmsCarrier::TestCase
  include ActiveSupport::LogSubscriber::TestHelper

  def setup
    super
    SmsCarrier::LogSubscriber.attach_to :sms_carrier
  end

  class TestCarrier < SmsCarrier::Base
    def receive(mail)
      # Do nothing
    end
  end

  def set_logger(logger)
    SmsCarrier::Base.logger = logger
  end

  def test_deliver_is_notified
    BaseCarrier.welcome.deliver_now
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match(/Sent SMS to \+886912345678/, @logger.logged(:info).first)

    assert_equal(2, @logger.logged(:debug).size)
    assert_match(/BaseCarrier#welcome: processed outbound SMS in [\d.]+ms/, @logger.logged(:debug).first)
    assert_match(/Welcome/, @logger.logged(:debug).second)
  ensure
    BaseCarrier.deliveries.clear
  end
end
