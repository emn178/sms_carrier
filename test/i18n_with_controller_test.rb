require 'abstract_unit'
require 'action_view'
require 'action_controller'

class I18nTestCarrier < SmsCarrier::Base
  configure do |c|
    c.assets_dir = ''
  end

  def sms_with_i18n_body(recipient)
    I18n.locale = :de
    sms(to: recipient, body: I18n.t(:sms_body), from: "+886987654321")
  end
end

class TestController < ActionController::Base
  def send_sms
    sms = I18nTestCarrier.sms_with_i18n_body("+886912345678").deliver_now
    render text: "Sms sent - Body: #{sms.body}"
  end
end

class ActionCarrierI18nWithControllerTest < ActionDispatch::IntegrationTest
  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    get ':controller(/:action(/:id))'
  end

  class RoutedRackApp
    attr_reader :routes

    def initialize(routes, &blk)
      @routes = routes
      @stack = ActionDispatch::MiddlewareStack.new(&blk).build(@routes)
    end

    def call(env)
      @stack.call(env)
    end
  end

  APP = RoutedRackApp.new(Routes)

  def app
    APP
  end

  teardown do
    I18n.locale = I18n.default_locale
  end

  def test_send_sms
    SmsCarrier::TestCarrier.any_instance.expects(:deliver!)
    with_translation 'de', sms_body: '[Anmeldung] Willkommen' do
      get '/test/send_sms'
      assert_equal "Sms sent - Body: [Anmeldung] Willkommen", @response.body
    end
  end

  protected

  def with_translation(locale, data)
    I18n.backend.store_translations(locale, data)
    yield
  ensure
    I18n.backend.reload!
  end
end
