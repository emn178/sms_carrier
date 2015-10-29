class BaseCarrier < SmsCarrier::Base
  self.carrier_name = "base_carrier"

  default to: '+886912345678',
          from: '+886987654321'

  def welcome(hash = {})
    options['X-SPAM'] = "Not SPAM"
    sms({subject: "The first SMS on new API!"}.merge!(hash))
  end

  def welcome_with_options(hash = {})
    options(hash)
    sms
  end

  def welcome_from_another_path(path)
    sms(template_name: "welcome", template_path: path)
  end

  def implicit_different_template(template_name='')
    sms(template_name: template_name)
  end

  def sms_with_translations
    sms body: render("sms_with_translations", formats: [:html])
  end

  def without_sms_call
  end

  def with_nil_as_return_value
    sms(template_name: "welcome")
    nil
  end

  def test_carrier_name
    sms(:body => '', :carrier_name => carrier_name)
  end
end
