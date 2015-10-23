require 'sms_carrier/test_carrier'

module SmsCarrier
  # This module handles everything related to SMS delivery, from registering
  # new delivery methods to configuring the SMS object to be sent.
  module DeliveryMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :delivery_methods, :delivery_method

      # Do not make this inheritable, because we always want it to propagate
      cattr_accessor :raise_delivery_errors
      self.raise_delivery_errors = true

      cattr_accessor :perform_deliveries
      self.perform_deliveries = true

      cattr_accessor :deliver_later_queue_name
      self.deliver_later_queue_name = :carriers

      self.delivery_methods = {}.freeze
      self.delivery_method  = :test

      add_delivery_method :test, TestCarrier
    end

    # Helpers for creating and wrapping delivery behavior, used by DeliveryMethods.
    module ClassMethods
      # Provides a list of SMSes that have been delivered by TestCarrier
      delegate :deliveries, :deliveries=, to: TestCarrier

      # Adds a new delivery method through the given class using the given
      # symbol as alias and the default options supplied.
      def add_delivery_method(symbol, klass, default_options = {})
        class_attribute(:"#{symbol}_settings") unless respond_to?(:"#{symbol}_settings")
        send(:"#{symbol}_settings=", default_options)
        self.delivery_methods = delivery_methods.merge(symbol.to_sym => klass).freeze
      end

      def wrap_delivery_behavior(sms, method = nil, options = nil) # :nodoc:
        method ||= delivery_method
        sms.delivery_handler = self

        case method
        when NilClass
          raise "Delivery method cannot be nil"
        when Symbol
          if klass = delivery_methods[method]
            sms.delivery_method(klass, (send(:"#{method}_settings") || {}).merge(options || {}))
          else
            raise "Invalid delivery method #{method.inspect}"
          end
        else
          sms.delivery_method(method)
        end

        sms.perform_deliveries    = perform_deliveries
        sms.raise_delivery_errors = raise_delivery_errors
      end
    end
    
    def wrap_delivery_behavior!(*args)  # :nodoc:
      self.class.wrap_delivery_behavior(message, *args)
    end
  end
end
