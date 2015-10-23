module SmsCarrier
  class TestCarrier
    attr_accessor :settings

    def initialize(settings)
      self.settings = settings
    end

    def deliver!(sms)
      TestCarrier.deliveries << sms
    end

    def self.deliveries
      @@deliveries ||= []
    end

    def self.deliveries=(val)
      @@deliveries = val
    end
  end
end
