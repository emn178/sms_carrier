require 'active_support/log_subscriber'

module SmsCarrier
  # Implements the ActiveSupport::LogSubscriber for logging notifications when
  # sms is delivered or received.
  class LogSubscriber < ActiveSupport::LogSubscriber
    # An SMS was delivered.
    def deliver(event)
      info do
        recipients = Array(event.payload[:to]).join(', ')
        "\nSent SMS to #{recipients} (#{event.duration.round(1)}ms)"
      end

      debug { event.payload[:sms] }
    end

    # An SMS was generated.
    def process(event)
      debug do
        carrier = event.payload[:carrier]
        action = event.payload[:action]
        "\n#{carrier}##{action}: processed outbound SMS in #{event.duration.round(1)}ms"
      end
    end

    # Use the logger configured for SmsCarrier::Base.
    def logger
      SmsCarrier::Base.logger
    end
  end
end

SmsCarrier::LogSubscriber.attach_to :sms_carrier
