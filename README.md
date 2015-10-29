# SMS Carrier

[![Build Status](https://api.travis-ci.org/emn178/sms_carrier.png)](https://travis-ci.org/emn178/sms_carrier)
[![Coverage Status](https://coveralls.io/repos/emn178/sms_carrier/badge.svg?branch=master)](https://coveralls.io/r/emn178/sms_carrier?branch=master)

SMS Carrier is a framework for designing SMS service layers. This is modified from Action Mailer of Rails framework, so the most of usage is just like Action Mailer.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sms_carrier'
```

And then execute:

    bundle

Or install it yourself as:

    gem install sms_carrier

## Usage
### Sending SMSes
You can use carrier and template to send SMSes.
```Ruby
class RegistrationCarrier < SmsCarrier::Base
  default from: '+886987654321'

  def welcome(recipient, token)
    @token = token
    sms(to: recipient)
  end
end
```
In your view, eg. `app/views/registration_carrier/welcome.erb.html`
```
Your token is <%= @token %>, please confirm your phone number
```

If the token was given as `1234`, the SMS generated would look like this:
```
Your token is 1234, please confirm your phone number
```

In order to send SMSes, you simply call the method and then call deliver_now on the return value.

Calling the method returns a Sms object:
```Ruby
sms = RegistrationCarrier.welcome("+886912345678", "1234")
sms.deliver_now
```
Or you can just chain the methods together like:
```Ruby
RegistrationCarrier.welcome("+886912345678", "1234").deliver_now
```

Or you can send SMS without carrier and template:
```Ruby
SmsCarrier::Base.sms(from: "+886987654321", to: "+886912345678", body: "Your token is #{token}, please confirm your phone number").deliver_now
```

### Deliver Later
SMS Carrier use Active Job like Action Mailer. So you can deliver SMS later, too:
```Ruby
sms.deliver_later
sms.deliver_later(wait_until: Date.tomorrow.noon)
sms.deliver_later(wait: 1.week)
```
Options are defined by Active Job, please refer to [Active Job](https://github.com/rails/rails/blob/7f18ea14c893cb5c9f04d4fda9661126758332b5/activejob/lib/active_job/enqueuing.rb#L32).

### Setting defaults
You can set up default settings in carrier by `default` method.
```Ruby
class AuthenticationCarrier < SmsCarrier::Base
  default from: "+886987654321", body: Proc.new { "SMS was generated at #{Time.now}" }
end
```
You can also set up in rails config, eg. `config/environments/production.rb`
```Ruby
config.sms_carrier.default_options = { from: "+886987654321" }
```

### Generators
You can run following commands to generate carriers:

    rails g carrier [name] [action] [action]...

Eg

    rails g carrier registration welcome

It creates a Registration carrier class and test:
```
Carrier:     app/carriers/registration_carrier.rb
Test:        test/carriers/registration_carrier_test.rb
or
RSpec:       spec/carriers/registration_carrier_spec.rb
```
And class looks like this:
```Ruby
class RegistrationCarrier < ApplicationCarrier
  def welcome
    # ...
  end
end
```

### Delivery Methods
You can also refer to the projects:
* [twilio-carrier](https://github.com/emn178/twilio-carrier): Twilio SMS service.
* [yunpian-carrier](https://github.com/emn178/yunpian-carrier): Yunpian(云片) SMS service.
* [dynamic-carrier](https://github.com/emn178/dynamic-carrier): A delivery method layer that decides the delivery method dynamically by your rules.
* [virtual_sms](https://github.com/emn178/virtual_sms): You can send SMS to a virtual SMS box instead of real SMS service in development environment.

You can implement your delivery method. 
```Ruby
class MyCarrier
  attr_accessor :settings

  def initialize(settings)
    self.settings = settings
  end

  def deliver!(sms)
    # sms.to is Array
    # my_deliver(sms.from, sms.to, sms.body)
  end
end
SmsCarrier::Base.add_delivery_method :my, MyCarrier
```
In your Rails project, you can set up in configuration:
```Ruby
config.sms_carrier.delivery_method = :my
config.sms_carrier.my_settings = {
  :settings => :pass_to_initialize
}
```

### Difference with Action Mailer
* SMS Carrier removed preview.
* SMS Carrier removed attachments feature.
* SMS Carrier removed multiple part rendering.
* SMS Carrier use `Hash` as options to replace the `Mail::Header` as headers in Action Mailer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contact
The project's website is located at https://github.com/emn178/sms_carrier  
Author: emn178@gmail.com
