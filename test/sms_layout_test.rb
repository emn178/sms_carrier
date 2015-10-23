require 'abstract_unit'

class AutoLayoutCarrier < SmsCarrier::Base
  default to: '+886987654321',
    from: "+886912345678"

  def hello
    sms()
  end

  def spam
    @world = "Earth"
    sms(body: render(inline: "Hello, <%= @world %>", layout: 'spam'))
  end

  def nolayout
    @world = "Earth"
    sms(body: render(inline: "Hello, <%= @world %>", layout: false))
  end
end

class ExplicitLayoutCarrier < SmsCarrier::Base
  layout 'spam', except: [:logout]

  default to: '+886987654321',
    from: "+886912345678"

  def signup
    sms()
  end

  def logout
    sms()
  end
end

class LayoutCarrierTest < ActiveSupport::TestCase
  def test_should_pickup_default_layout
    sms = AutoLayoutCarrier.hello
    assert_equal "Hello from layout Inside", sms.body.to_s.strip
  end

  def test_should_pickup_layout_given_to_render
    sms = AutoLayoutCarrier.spam
    assert_equal "Spammer layout Hello, Earth", sms.body.to_s.strip
  end

  def test_should_respect_layout_false
    sms = AutoLayoutCarrier.nolayout
    assert_equal "Hello, Earth", sms.body.to_s.strip
  end

  def test_explicit_class_layout
    sms = ExplicitLayoutCarrier.signup
    assert_equal "Spammer layout We do not spam", sms.body.to_s.strip
  end

  def test_explicit_layout_exceptions
    sms = ExplicitLayoutCarrier.logout
    assert_equal "You logged out", sms.body.to_s.strip
  end
end
