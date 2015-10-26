require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/hash/reverse_merge'

require 'sms_carrier/sms'
require 'sms_carrier/log_subscriber'

module SmsCarrier
  class Base < AbstractController::Base
    include DeliveryMethods

    abstract!

    include AbstractController::Rendering

    include AbstractController::Logger
    include AbstractController::Helpers
    include AbstractController::Translation
    include AbstractController::AssetPaths
    include AbstractController::Callbacks

    include ActionView::Layouts

    PROTECTED_IVARS = AbstractController::Rendering::DEFAULT_PROTECTED_INSTANCE_VARIABLES + [:@_action_has_layout]

    def _protected_ivars # :nodoc:
      PROTECTED_IVARS
    end

    private_class_method :new #:nodoc:

    class_attribute :default_params
    self.default_params = {}.freeze

    class << self
      # Register one or more Observers which will be notified when SMS is delivered.
      def register_observers(*observers)
        observers.flatten.compact.each { |observer| register_observer(observer) }
      end

      # Register one or more Interceptors which will be called before SMS is sent.
      def register_interceptors(*interceptors)
        interceptors.flatten.compact.each { |interceptor| register_interceptor(interceptor) }
      end

      # Register an Observer which will be notified when SMS is delivered.
      # Either a class, string or symbol can be passed in as the Observer.
      # If a string or symbol is passed in it will be camelized and constantized.
      def register_observer(observer)
        delivery_observer = case observer
          when String, Symbol
            observer.to_s.camelize.constantize
          else
            observer
          end

        Sms.register_observer(delivery_observer)
      end

      # Register an Interceptor which will be called before SMS is sent.
      # Either a class, string or symbol can be passed in as the Interceptor.
      # If a string or symbol is passed in it will be camelized and constantized.
      def register_interceptor(interceptor)
        delivery_interceptor = case interceptor
          when String, Symbol
            interceptor.to_s.camelize.constantize
          else
            interceptor
          end

        Sms.register_interceptor(delivery_interceptor)
      end

      # Returns the name of current carrier.
      # If this is an anonymous carrier, this method will return +anonymous+ instead.
      def carrier_name
        @carrier_name ||= anonymous? ? "anonymous" : name.underscore
      end
      # Allows to set the name of current carrier.
      attr_writer :carrier_name
      alias :controller_path :carrier_name

      # Sets the defaults through app configuration:
      #
      #     config.sms_carrier.default(from: "+886987654321")
      #
      # Aliased by ::default_options=
      def default(value = nil)
        self.default_params = default_params.merge(value).freeze if value
        default_params
      end
      # Allows to set defaults through app configuration:
      #
      #    config.sms_carrier.default_options = { from: "+886987654321" }
      alias :default_options= :default

      # Wraps an SMS delivery inside of <tt>ActiveSupport::Notifications</tt> instrumentation.
      #
      # This method is actually called by the <tt>Sms</tt> object itself
      # through a callback when you call <tt>:deliver</tt> on the <tt>Sms</tt>,
      # calling +deliver_sms+ directly and passing a <tt>Sms</tt> will do
      # nothing except tell the logger you sent the SMS.
      def deliver_sms(sms) #:nodoc:
        ActiveSupport::Notifications.instrument("deliver.sms_carrier") do |payload|
          set_payload_for_sms(payload, sms)
          yield # Let Sms do the delivery actions
        end
      end

      def respond_to?(method, include_private = false) #:nodoc:
        super || action_methods.include?(method.to_s)
      end

      protected

      def set_payload_for_sms(payload, sms) #:nodoc:
        payload[:carrier]     = name
        payload[:to]         = sms.to
        payload[:from]       = sms.from
        payload[:sms]        = sms.body
      end

      def method_missing(method_name, *args) #:nodoc:
        if action_methods.include?(method_name.to_s)
          MessageDelivery.new(self, method_name, *args)
        else
          super
        end
      end
    end

    attr_internal :message

    # Instantiate a new carrier object. If +method_name+ is not +nil+, the carrier
    # will be initialized according to the named method. If not, the carrier will
    # remain uninitialized (useful when you only need to invoke the "receive"
    # method, for instance).
    def initialize(method_name=nil, *args)
      super()
      @_sms_was_called = false
      @_message = Sms.new
      process(method_name, *args) if method_name
    end

    def process(method_name, *args) #:nodoc:
      payload = {
        carrier: self.class.name,
        action: method_name
      }

      ActiveSupport::Notifications.instrument("process.sms_carrier", payload) do
        super
        @_message = NullMessage.new unless @_sms_was_called
      end
    end

    class NullMessage #:nodoc:
      def body; '' end

      def respond_to?(string, include_all=false)
        true
      end

      def method_missing(*args)
        nil
      end
    end

    # Returns the name of the carrier object.
    def carrier_name
      self.class.carrier_name
    end

    # Allows you to pass random and unusual options to the new <tt>SmsCarrier::Sms</tt>
    # object which will add them to itself.
    #
    #   options['X-Special-Domain-Specific-Option'] = "SecretValue"
    #
    # The resulting <tt>SmsCarrier::Sms</tt> will have the following in its option:
    #
    #   X-Special-Domain-Specific-Option: SecretValue
    # def options
    #   @_message.options
    # end

    def options(args = nil)
      if args
        @_message.options.merge!(args)
      else
        @_message
      end
    end

    # The main method that creates the message and renders the SMS templates. There are
    # two ways to call this method, with a block, or without a block.
    #
    # It accepts a headers hash. This hash allows you to specify
    # the most used headers in an SMS message, these are:
    #
    # * +:to+ - Who the message is destined for, can be a string of addresses, or an array
    #   of addresses.
    # * +:from+ - Who the message is from
    #
    # You can set default values for any of the above headers (except +:date+)
    # by using the ::default class method:
    #
    #  class Notifier < SmsCarrier::Base
    #    default from: '+886987654321'
    #  end
    #
    # If you do not pass a block to the +sms+ method, it will find all
    # templates in the view paths using by default the carrier name and the
    # method name that it is being called from, it will then create parts for
    # each of these templates intelligently, making educated guesses on correct
    # content type and sequence, and return a fully prepared <tt>Sms</tt>
    # ready to call <tt>:deliver</tt> on to send.
    #
    # For example:
    #
    #   class Notifier < SmsCarrier::Base
    #     default from: 'no-reply@test.lindsaar.net'
    #
    #     def welcome
    #       sms(to: 'mikel@test.lindsaar.net')
    #     end
    #   end
    #
    # Will look for all templates at "app/views/notifier" with name "welcome".
    # If no welcome template exists, it will raise an ActionView::MissingTemplate error.
    #
    # However, those can be customized:
    #
    #   sms(template_path: 'notifications', template_name: 'another')
    #
    # And now it will look for all templates at "app/views/notifications" with name "another".
    #
    # You can even render plain text directly without using a template:
    #
    #   sms(to: '+886987654321', body: 'Hello Mikel!')
    #
    def sms(options = {})
      return @_message if @_sms_was_called && options.blank?

      m = @_message

      # Call all the procs (if any)
      default_values = {}
      self.class.default.each do |k,v|
        default_values[k] = v.is_a?(Proc) ? instance_eval(&v) : v
      end

      # Handle defaults
      options = options.reverse_merge(default_values)

      # Set configure delivery behavior
      wrap_delivery_behavior!(options.delete(:delivery_method), options.delete(:delivery_method_options))

      # Assign all options except body, template_name, and template_path
      assignable = options.except(:body, :template_name, :template_path)
      assignable.each { |k, v| m[k] = v }

      # Render the templates and blocks
      m.body = response(options)
      @_sms_was_called = true

      m
    end

    def response(options) #:nodoc:
      if options[:body]
        return options.delete(:body)
      else
        templates_path = options.delete(:template_path) || self.class.carrier_name
        templates_name = options.delete(:template_name) || action_name

        template = lookup_context.find(templates_name, templates_path)
        if template.nil?
          raise ActionView::MissingTemplate.new(templates_path, templates_name, templates_path, false, 'carrier')
        else
          return render(template: template)
        end
      end
    end

    # SMS do not support relative path links.
    def self.supports_path?
      false
    end

    ActiveSupport.run_load_hooks(:sms_carrier, self)
  end
end
