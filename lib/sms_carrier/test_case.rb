require 'active_support/test_case'

module SmsCarrier
  class NonInferrableCarrierError < ::StandardError
    def initialize(name)
      super "Unable to determine the carrier to test from #{name}. " +
        "You'll need to specify it using tests YourCarrier in your " +
        "test case definition"
    end
  end

  class TestCase < ActiveSupport::TestCase
    module Behavior
      extend ActiveSupport::Concern

      include ActiveSupport::Testing::ConstantLookup
      include TestHelper

      included do
        class_attribute :_carrier_class
        setup :initialize_test_deliveries
        setup :set_expected_sms
        teardown :restore_test_deliveries
      end

      module ClassMethods
        def tests(carrier)
          case carrier
          when String, Symbol
            self._carrier_class = carrier.to_s.camelize.constantize
          when Module
            self._carrier_class = carrier
          else
            raise NonInferrableCarrierError.new(carrier)
          end
        end

        def carrier_class
          if carrier = self._carrier_class
            carrier
          else
            tests determine_default_carrier(name)
          end
        end

        def determine_default_carrier(name)
          carrier = determine_constant_from_test_name(name) do |constant|
            Class === constant && constant < SmsCarrier::Base
          end
          raise NonInferrableCarrierError.new(name) if carrier.nil?
          carrier
        end
      end

      protected

      def initialize_test_deliveries # :nodoc:
        set_delivery_method :test
        @old_perform_deliveries = SmsCarrier::Base.perform_deliveries
        SmsCarrier::Base.perform_deliveries = true
      end

      def restore_test_deliveries # :nodoc:
        restore_delivery_method
        SmsCarrier::Base.perform_deliveries = @old_perform_deliveries
        SmsCarrier::Base.deliveries.clear
      end

      def set_delivery_method(method) # :nodoc:
        @old_delivery_method = SmsCarrier::Base.delivery_method
        SmsCarrier::Base.delivery_method = method
      end

      def restore_delivery_method # :nodoc:
        SmsCarrier::Base.delivery_method = @old_delivery_method
      end

      def set_expected_sms # :nodoc:
        @expected = Sms.new
      end
    end

    include Behavior
  end
end
