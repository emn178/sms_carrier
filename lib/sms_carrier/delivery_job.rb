require 'active_job'

module SmsCarrier
  # The <tt>SmsCarrier::DeliveryJob</tt> class is used when you
  # want to send SMSes outside of the request-response cycle.
  class DeliveryJob < ActiveJob::Base # :nodoc:
    queue_as { SmsCarrier::Base.deliver_later_queue_name }

    def perform(sms, sms_method, delivery_method, *args) #:nodoc:
      sms.constantize.public_send(sms_method, *args).send(delivery_method)
    end
  end
end
