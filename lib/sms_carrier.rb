require 'abstract_controller'
require 'sms_carrier/version'

# Common Active Support usage in SmsCarrier
require 'active_support/rails'
require 'active_support/core_ext/class'
require 'active_support/core_ext/module/attr_internal'
require 'active_support/core_ext/string/inflections'
require 'active_support/lazy_load_hooks'

module SmsCarrier
  extend ::ActiveSupport::Autoload

  autoload :Base
  autoload :DeliveryMethods
  autoload :TestCase
  autoload :TestHelper
  autoload :MessageDelivery
  autoload :DeliveryJob
end

require "sms_carrier/railtie" if defined? ::Rails
