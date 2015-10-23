# SMS Carrier

[![Build Status](https://api.travis-ci.org/emn178/sms_carrier.png)](https://travis-ci.org/emn178/sms_carrier)
[![Coverage Status](https://coveralls.io/repos/emn178/sms_carrier/badge.svg?branch=master)](https://coveralls.io/r/emn178/sms_carrier?branch=master)

SMS Carrier is a framework for designing SMS service layers. These layers are used to consolidate code for sending out confirmation token, and any other use case that requires a written notification to either a person or another system.

SMS Carrier is in essence a wrapper around Action Controller. It provides a way to make SMSes using templates in the same way that Action Controller renders views using templates.

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
The framework works by initializing any instance variables you want to be available in the SMS template, followed by a call to sms to deliver the SMS.

This can be as simple as:
```Ruby
class Notifier < SmsCarrier::Base
  default from: '+886987654321'

  def welcome(recipient, token)
    @token = token
    sms(to: recipient)
  end
end
```
The body of the SMS is created by using an Action View template (regular ERB) that has the instance variables that are declared in the carrier action.

So the corresponding body template for the method above could look like this:
```
Your token is <%= @token %>, please confirm your phone number
```
If the token was given as “1234”, the SMS generated would look like this:
```
Your token is 1234, please confirm your phone number
```
In order to send SMSes, you simply call the method and then call deliver_now on the return value.

Calling the method returns a Sms object:
```Ruby
message = Notifier.welcome("1234")   # => Returns a SmsCarrier::Sms object
message.deliver_now                  # => delivers the SMS
```
Or you can just chain the methods together like:
```Ruby
Notifier.welcome("1234").deliver_now # Creates the SMS and sends it immediately
```
Or you can send SMS without carrier and template:
```Ruby
SmsCarrier::Base.sms(from: "+886987654321", to: "+886912345678", body: "Your token is #{@token}").deliver_now
```

### Setting defaults
It is possible to set default values that will be used in every method in your SMS Carrier class. To implement this functionality, you just call the public class method default which you get for free from SmsCarrier::Base. This method accepts a Hash as the parameter. You can use any of the options, SMS messages have, like :from as the key. You can also pass in a string as the key, like “Content-Type”, but SMS Carrier does this out of the box for you, so you won't need to worry about that. Finally, it is also possible to pass in a Proc that will get evaluated when it is needed.

Note that every value you set with this method will get overwritten if you use the same key in your carrier method.

Example:
```Ruby
class AuthenticationCarrier < SmsCarrier::Base
  default from: "+886987654321", body: Proc.new { "SMS was generated at #{Time.now}" }
  .....
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contact
The project's website is located at https://github.com/emn178/sms_carrier  
Author: emn178@gmail.com
