require 'delegate'

module SmsCarrier
  # The <tt>SmsCarrier::MessageDelivery</tt> class is used by
  # <tt>SmsCarrier::Base</tt> when creating a new carrier.
  # <tt>MessageDelivery</tt> is a wrapper (+Delegator+ subclass) around a lazy
  # created <tt>Sms</tt>. You can get direct access to the
  # <tt>Sms</tt>, deliver the SMS or schedule the SMS to be sent
  # through Active Job.
  #
  #   Notifier.welcome(User.first)               # an SmsCarrier::MessageDelivery object
  #   Notifier.welcome(User.first).deliver_now   # sends the email
  #   Notifier.welcome(User.first).deliver_later # enqueue email delivery as a job through Active Job
  #   Notifier.welcome(User.first).message       # a Sms object
  class MessageDelivery < Delegator
    def initialize(carrier, sms_method, *args)  #:nodoc:
      @carrier = carrier
      @sms_method = sms_method
      @args = args
    end

    def __getobj__  #:nodoc:
      @obj ||= @carrier.send(:new, @sms_method, *@args).message
    end

    def __setobj__(obj)  #:nodoc:
      @obj = obj
    end

    # Returns the Message object
    def message
      __getobj__
    end

    # Enqueues the SMS to be delivered through Active Job. When the
    # job runs it will send the SMS using +deliver_now!+. That means
    # that the message will be sent bypassing checking +perform_deliveries+
    # and +raise_delivery_errors+, so use with caution.
    #
    #   Notifier.welcome(User.first).deliver_later!
    #   Notifier.welcome(User.first).deliver_later!(wait: 1.hour)
    #   Notifier.welcome(User.first).deliver_later!(wait_until: 10.hours.from_now)
    #
    # Options:
    #
    # * <tt>:wait</tt> - Enqueue the SMS to be delivered with a delay
    # * <tt>:wait_until</tt> - Enqueue the SMS to be delivered at (after) a specific date / time
    # * <tt>:queue</tt> - Enqueue the SMS on the specified queue
    def deliver_later!(options={})
      enqueue_delivery :deliver_now!, options
    end

    # Enqueues the SMS to be delivered through Active Job. When the
    # job runs it will send the SMS using +deliver_now+.
    #
    #   Notifier.welcome(User.first).deliver_later
    #   Notifier.welcome(User.first).deliver_later(wait: 1.hour)
    #   Notifier.welcome(User.first).deliver_later(wait_until: 10.hours.from_now)
    #
    # Options:
    #
    # * <tt>:wait</tt> - Enqueue the SMS to be delivered with a delay.
    # * <tt>:wait_until</tt> - Enqueue the SMS to be delivered at (after) a specific date / time.
    # * <tt>:queue</tt> - Enqueue the SMS on the specified queue.
    def deliver_later(options={})
      enqueue_delivery :deliver_now, options
    end

    # Delivers an SMS without checking +perform_deliveries+ and +raise_delivery_errors+,
    # so use with caution.
    #
    #   Notifier.welcome(User.first).deliver_now!
    #
    def deliver_now!
      message.deliver!
    end

    # Delivers an SMS:
    #
    #   Notifier.welcome(User.first).deliver_now
    #
    def deliver_now
      message.deliver
    end

    private

    def enqueue_delivery(delivery_method, options={})
      args = @carrier.name, @sms_method.to_s, delivery_method.to_s, *@args
      SmsCarrier::DeliveryJob.set(options).perform_later(*args)
    end
  end
end
