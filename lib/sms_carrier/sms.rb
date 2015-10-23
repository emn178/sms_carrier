module SmsCarrier
  class Sms
    attr_accessor :body, :from, :to, :options, :perform_deliveries, :raise_delivery_errors, :delivery_handler

    def initialize
      @options = {}
      @perform_deliveries = true
      @raise_delivery_errors = true
      @to = []
    end

    def [](name)
      options[name]
    end

    def []=(name, value)
      if name.to_s == 'body'
        self.body = value
      elsif name.to_s == 'from'
        self.from = value
      elsif name.to_s == 'to'
        self.to = value
      else
        options[name] = value
      end
    end

    def to( val = nil )
      if val.nil?
        @to
      elsif val.is_a? Array
        @to = @to + val
      elsif !@to.include? val
        @to << val
      end
    end

    def to=( val )
      to(val)
    end

    def inform_observers
      Sms.inform_observers(self)
    end

    def inform_interceptors
      Sms.inform_interceptors(self)
    end

    def deliver
      inform_interceptors
      if delivery_handler
        delivery_handler.deliver_sms(self) { do_delivery }
      else
        do_delivery
      end
      inform_observers
      self
    end

    def deliver!
      inform_interceptors
      response = delivery_method.deliver!(self)
      inform_observers
      delivery_method.settings[:return_response] ? response : self
    end

    def delivery_method(method = nil, settings = {})
      unless method
        @delivery_method
      else
        @delivery_method = method.new(settings)
      end
    end

    def to_s
      buffer = ''
      options.each do |key, value|
        buffer += "#{key}: #{value}\n"
      end
      buffer += "From: #{from}\n"
      buffer += "To: #{to}\n"
      buffer += "Body: #{body}\n"
      buffer
    end

    @@delivery_notification_observers = []
    @@delivery_interceptors = []

    def self.register_observer(observer)
      unless @@delivery_notification_observers.include?(observer)
        @@delivery_notification_observers << observer
      end
    end

    def self.register_interceptor(interceptor)
      unless @@delivery_interceptors.include?(interceptor)
        @@delivery_interceptors << interceptor
      end
    end

    def self.inform_observers(sms)
      @@delivery_notification_observers.each do |observer|
        observer.delivered_sms(sms)
      end
    end

    def self.inform_interceptors(sms)
      @@delivery_interceptors.each do |interceptor|
        interceptor.delivering_sms(sms)
      end
    end

    private

    def do_delivery
      begin
        if perform_deliveries
          delivery_method.deliver!(self)
        end
      rescue => e
        raise e if raise_delivery_errors
      end
    end
  end
end
