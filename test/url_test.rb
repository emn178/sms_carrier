require 'abstract_unit'
require 'action_controller'

class WelcomeController < ActionController::Base
end

AppRoutes = ActionDispatch::Routing::RouteSet.new

class SmsCarrier::Base
  include AppRoutes.url_helpers
end

class UrlTestCarrier < SmsCarrier::Base
  default_url_options[:host] = 'www.basecamphq.com'

  configure do |c|
    c.assets_dir = '' # To get the tests to pass
  end

  def signed_up_with_url(recipient)
    @recipient   = recipient
    @welcome_url = url_for host: "example.com", controller: "welcome", action: "greeting"
    sms(to: recipient, subject: "[Signed up] Welcome #{recipient}",
      from: "+886987654321")
  end

  def exercise_url_for(options)
    @options = options
    @url = url_for(@options)
    sms(from: '+886987654321', to: '+886912345678', subject: 'subject')
  end
end

class SmsCarrierUrlTest < SmsCarrier::TestCase
  class DummyModel
    def self.model_name
      OpenStruct.new(route_key: 'dummy_model')
    end

    def persisted?
      false
    end

    def model_name
      self.class.model_name
    end

    def to_model
      self
    end
  end

  def encode( text )
    quoted_printable( text, charset )
  end

  def new_sms
    SmsCarrier::Sms.new
  end

  def assert_url_for(expected, options, relative = false)
    expected = "http://www.basecamphq.com#{expected}" if expected.start_with?('/') && !relative
    urls = UrlTestCarrier.exercise_url_for(options).body.to_s.chomp.split

    assert_equal expected, urls.first
    assert_equal expected, urls.second
  end

  def setup
    @recipient = '+886912345678'
  end

  def test_url_for
    UrlTestCarrier.delivery_method = :test

    AppRoutes.draw do
      get ':controller(/:action(/:id))'
      get '/welcome'  => 'foo#bar', as: 'welcome'
      get '/dummy_model' => 'foo#baz', as: 'dummy_model'
    end

    # string
    assert_url_for 'http://foo/', 'http://foo/'

    # symbol
    assert_url_for '/welcome', :welcome

    # hash
    assert_url_for '/a/b/c', controller: 'a', action: 'b', id: 'c'
    assert_url_for '/a/b/c', {controller: 'a', action: 'b', id: 'c', only_path: true}, true

    # model
    assert_url_for '/dummy_model', DummyModel.new

    # class
    assert_url_for '/dummy_model', DummyModel

    # array
    assert_url_for '/dummy_model' , [DummyModel]
  end

  def test_signed_up_with_url
    UrlTestCarrier.delivery_method = :test

    AppRoutes.draw do
      get ':controller(/:action(/:id))'
      get '/welcome' => "foo#bar", as: "welcome"
    end

    expected = new_sms
    expected.to      = @recipient
    expected.body    = "Hello there,\n\nMr. #{@recipient}. Please see our greeting at http://example.com/welcome/greeting http://www.basecamphq.com/welcome\n\n/images/somelogo.png\n"
    expected.from    = "+886987654321"

    created = nil
    assert_nothing_raised { created = UrlTestCarrier.signed_up_with_url(@recipient) }
    assert_not_nil created

    assert_equal expected.from, created.from
    assert_equal expected.to, created.to
    assert_equal expected.body, created.body

    assert_nothing_raised { UrlTestCarrier.signed_up_with_url(@recipient).deliver_now }
    assert_not_nil SmsCarrier::Base.deliveries.first
    delivered = SmsCarrier::Base.deliveries.first

    assert_equal expected.from, delivered.from
    assert_equal expected.to, delivered.to
    assert_equal expected.body, delivered.body
  end
end
