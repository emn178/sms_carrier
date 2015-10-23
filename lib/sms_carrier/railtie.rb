require 'active_job/railtie'
require "sms_carrier"
require "rails"
require "abstract_controller/railties/routes_helpers"

module SmsCarrier
  class Railtie < Rails::Railtie # :nodoc:
    config.sms_carrier = ActiveSupport::OrderedOptions.new
    config.eager_load_namespaces << SmsCarrier

    initializer "sms_carrier.logger" do
      ActiveSupport.on_load(:sms_carrier) { self.logger ||= Rails.logger }
    end

    initializer "sms_carrier.set_configs" do |app|
      paths   = app.config.paths
      options = app.config.sms_carrier

      options.assets_dir      ||= paths["public"].first
      options.javascripts_dir ||= paths["public/javascripts"].first
      options.stylesheets_dir ||= paths["public/stylesheets"].first

      # make sure readers methods get compiled
      options.asset_host          ||= app.config.asset_host
      options.relative_url_root   ||= app.config.relative_url_root

      ActiveSupport.on_load(:sms_carrier) do
        include AbstractController::UrlFor
        extend ::AbstractController::Railties::RoutesHelpers.with(app.routes, false)
        include app.routes.mounted_helpers

        register_interceptors(options.delete(:interceptors))
        register_observers(options.delete(:observers))

        options.each { |k,v| send("#{k}=", v) }
      end
    end

    initializer "sms_carrier.compile_config_methods" do
      ActiveSupport.on_load(:sms_carrier) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end
  end
end
