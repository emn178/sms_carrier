# encoding: utf-8
require 'abstract_unit'
require 'active_job'
require 'minitest/mock'
require 'carriers/delayed_carrier'
require 'active_support/core_ext/numeric/time'

class MessageDeliveryTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @previous_logger = ActiveJob::Base.logger
    @previous_delivery_method = SmsCarrier::Base.delivery_method
    SmsCarrier::Base.delivery_method = :test
    ActiveJob::Base.logger = Logger.new(nil)
    @sms = DelayedCarrier.test_message(1, 2, 3)
    SmsCarrier::Base.deliveries.clear
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
  end

  teardown do
    ActiveJob::Base.logger = @previous_logger
    SmsCarrier::Base.delivery_method = @previous_delivery_method
  end

  test 'should have a message' do
    assert @sms.message
  end

  test 'its message should be a SmsCarrier::Sms' do
    assert_equal SmsCarrier::Sms , @sms.message.class
  end

  test 'should respond to .deliver_later' do
    assert_respond_to @sms, :deliver_later
  end

  test 'should respond to .deliver_later!' do
    assert_respond_to @sms, :deliver_later!
  end

  test 'should respond to .deliver_now' do
    assert_respond_to @sms, :deliver_now
  end

  test 'should respond to .deliver_now!' do
    assert_respond_to @sms, :deliver_now!
  end

  def test_should_enqueue_and_run_correctly_in_activejob
    @sms.deliver_later!
    assert_equal 1, SmsCarrier::Base.deliveries.size
  ensure
    SmsCarrier::Base.deliveries.clear
  end

  test 'should enqueue the SMS with :deliver_now delivery method' do
    assert_performed_with(job: SmsCarrier::DeliveryJob, args: ['DelayedCarrier', 'test_message', 'deliver_now', 1, 2, 3]) do
      @sms.deliver_later
    end
  end

  test 'should enqueue the SMS with :deliver_now! delivery method' do
    assert_performed_with(job: SmsCarrier::DeliveryJob, args: ['DelayedCarrier', 'test_message', 'deliver_now!', 1, 2, 3]) do
      @sms.deliver_later!
    end
  end

  test 'should enqueue a delivery with a delay' do
    travel_to Time.new(2004, 11, 24, 01, 04, 44) do
      assert_performed_with(job: SmsCarrier::DeliveryJob, at: Time.current.to_f+600.seconds, args: ['DelayedCarrier', 'test_message', 'deliver_now', 1, 2, 3]) do
        @sms.deliver_later wait: 600.seconds
      end
    end
  end

  test 'should enqueue a delivery at a specific time' do
    later_time = Time.now.to_f + 3600
    assert_performed_with(job: SmsCarrier::DeliveryJob, at: later_time, args: ['DelayedCarrier', 'test_message', 'deliver_now', 1, 2, 3]) do
      @sms.deliver_later wait_until: later_time
    end
  end

  test 'should set message obj' do
    sms = SmsCarrier::Base.sms(:body => 'AAA')
    ref = sms
    sms.__setobj__(SmsCarrier::Base.sms(:body => 'BBB'))
    assert_equal 'BBB', ref.body
  end
end
